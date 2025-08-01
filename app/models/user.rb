class User < ApplicationRecord
  include Clearance::User
  include Discard::Model
  include Events::Recordable
  include Gravtastic
  include UserMultifactorMethods

  is_gravtastic default: "retro"

  self.discard_column = :deleted_at

  default_scope { not_deleted }

  before_save :_generate_confirmation_token_no_reset_unconfirmed_email, if: :will_save_change_to_unconfirmed_email?
  before_create :_generate_confirmation_token_no_reset_unconfirmed_email
  after_create :record_create_event
  after_update :record_email_update_event, if: :email_was_updated?
  after_update :record_email_verified_event, if: -> { saved_change_to_email? && email_confirmed? }
  after_update :record_password_update_event, if: :saved_change_to_encrypted_password?
  after_update :record_policies_acknowledged_event, if: :saved_change_to_policies_acknowledged_at?
  before_discard :yank_gems
  before_discard :expire_all_api_keys
  before_discard :destroy_associations_for_discard
  before_discard :clear_personal_attributes
  after_discard :send_deletion_complete_email
  before_destroy :yank_gems

  scope :not_deleted, -> { kept }
  scope :deleted, -> { with_discarded.discarded }
  scope :with_deleted, -> { with_discarded }
  scope :confirmed, -> { where(email_confirmed: true) }

  has_many :ownerships, -> { confirmed }, dependent: :destroy, inverse_of: :user

  has_many :rubygems, through: :ownerships, source: :rubygem
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_gems, -> { order("name ASC") }, through: :subscriptions, source: :rubygem

  has_many :rubygems_downloaded,
    -> { with_versions.joins(:gem_download).order(GemDownload.arel_table["count"].desc) },
    through: :ownerships,
    source: :rubygem

  has_many :pushed_versions, -> { by_created_at }, dependent: :nullify, inverse_of: :pusher, class_name: "Version", foreign_key: :pusher_id
  has_many :yanked_versions, through: :deletions, source: :version, inverse_of: :yanker

  has_many :deletions, dependent: :nullify
  has_many :web_hooks, dependent: :destroy

  # used for deleting unconfirmed ownerships as well on user destroy
  has_many :unconfirmed_ownerships, -> { unconfirmed }, dependent: :destroy, inverse_of: :user, class_name: "Ownership"
  has_many :api_keys, dependent: :destroy, inverse_of: :owner, as: :owner

  has_many :audits, as: :auditable, dependent: :nullify
  has_many :rubygem_events, through: :rubygems, source: :events

  has_many :oidc_api_key_roles, dependent: :nullify, class_name: "OIDC::ApiKeyRole", inverse_of: :user
  has_many :oidc_id_tokens, through: :oidc_api_key_roles, class_name: "OIDC::IdToken", inverse_of: :user, source: :id_tokens
  has_many :oidc_providers, through: :oidc_api_key_roles, class_name: "OIDC::Provider", inverse_of: :users, source: :provider
  has_many :oidc_pending_trusted_publishers, class_name: "OIDC::PendingTrustedPublisher", inverse_of: :user, dependent: :destroy
  has_many :oidc_rubygem_trusted_publishers, through: :rubygems, class_name: "OIDC::RubygemTrustedPublisher"

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships

  has_many :organization_onboardings, foreign_key: :created_by_id, dependent: :nullify, inverse_of: :created_by

  validates :email, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true,
    uniqueness: { case_sensitive: false }
  validates :unconfirmed_email, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  validates :handle, uniqueness: { case_sensitive: false }, allow_nil: true, if: :handle_changed?
  validates :handle, format: { with: Patterns::HANDLE_PATTERN }, length: { within: 2..40 }, allow_nil: true
  validate :unique_with_org_handle

  validates :twitter_username, format: {
    with: /\A[a-zA-Z0-9_]*\z/,
    message: "can only contain letters, numbers, and underscores"
  }, allow_nil: true, length: { within: 0..20 }

  validates :password,
    length: { minimum: 10 },
    unpwn: true,
    allow_blank: true, # avoid double errors with can't be blank
    unless: :skip_password_validation?

  validates :full_name, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }, allow_nil: true

  validate :unconfirmed_email_uniqueness
  validate :toxic_email_domain, on: :create
  validate :password_byte_length

  def self.authenticate(who, password)
    # Avoid exceptions when string is invalid in the given encoding, _or_ cannot be converted
    # to UTF-8.
    who = who.encode(Encoding::UTF_8)

    user = find_by_email(who) || find_by(handle: who)
    user if user&.authenticated?(password)
  rescue BCrypt::Errors::InvalidHash, Encoding::UndefinedConversionError
    nil
  end

  def self.find_by_email(email)
    find_by("lower(email) = lower(?)", email)
  end

  def self.find_by_slug!(slug)
    raise ActiveRecord::RecordNotFound if slug.blank?
    find_by(id: slug) || find_by!(handle: slug)
  end

  def self.find_by_slug(slug)
    return if slug.blank?
    find_by(id: slug) || find_by(handle: slug)
  end

  def self.find_by_name!(name)
    raise ActiveRecord::RecordNotFound if name.blank?
    find_by_email(name) || find_by!(handle: name)
  end

  def self.find_by_name(name)
    return if name.blank?
    find_by_email(name) || find_by(handle: name)
  end

  def self.find_by_blocked(slug)
    return if slug.blank?
    find_by(blocked_email: slug) || find_by(handle: slug)
  end

  def self.push_notifiable_owners
    where(ownerships: { push_notifier: true })
  end

  def self.ownership_notifiable_owners
    where(ownerships: { owner_notifier: true })
  end

  def self.normalize_email(email)
    email.to_s.gsub(/\s+/, "")
  rescue ArgumentError
    ""
  end

  def self.security_user
    find_by!(email: "security@rubygems.org")
  end

  def name
    handle || email
  end

  def display_handle
    handle || "##{id}"
  end

  def display_id
    handle || id
  end

  def flipper_id
    "user:#{handle}"
  end

  def reset_api_key!
    generate_api_key && save!
  end

  def all_hooks
    all     = web_hooks.specific.group_by { |hook| hook.rubygem.name }
    globals = web_hooks.global.to_a
    all["all gems"] = globals if globals.present?
    all
  end

  def payload
    attrs = { "id" => id, "handle" => handle }
    attrs["email"] = email if public_email?
    attrs
  end

  delegate :as_json, :to_yaml, to: :payload

  def to_xml(options = {})
    payload.to_xml(options.merge(root: "user"))
  end

  def encode_with(coder)
    coder.tag = nil
    coder.implicit = true
    coder.map = payload
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end

  def total_downloads_count
    rubygems.joins(:gem_download).sum(:count)
  end

  def total_rubygems_count
    rubygems.with_versions.count
  end

  def confirm_email!
    return false if unconfirmed_email && !update_email
    update!(email_confirmed: true, confirmation_token: nil, token_expires_at: Time.zone.now)
  end

  # confirmation token expires after 3 hours
  def valid_confirmation_token?
    confirmation_token.present? && Time.zone.now.before?(token_expires_at)
  end

  def generate_confirmation_token(reset_unconfirmed_email: true)
    self.unconfirmed_email = nil if reset_unconfirmed_email
    self.confirmation_token = SecureRandom.hex(24)
    self.token_expires_at = Time.zone.now + Gemcutter::EMAIL_TOKEN_EXPIRES_AFTER
  end

  def _generate_confirmation_token_no_reset_unconfirmed_email
    generate_confirmation_token(reset_unconfirmed_email: false)
  end

  def unconfirmed?
    !email_confirmed
  end

  def only_owner_gems
    rubygems.with_versions.where('rubygems.id IN (
      SELECT rubygem_id FROM ownerships GROUP BY rubygem_id HAVING count(rubygem_id) = 1)')
  end

  def remember_me!
    self.remember_token = Clearance::Token.new
    self.remember_token_expires_at = Gemcutter::REMEMBER_FOR.from_now
    save!(validate: false)
    remember_token
  end

  def remember_me?
    remember_token_expires_at && remember_token_expires_at > Time.zone.now
  end

  def block!
    original_email = email
    transaction do
      update_attribute(:email, "security+locked-#{SecureRandom.hex(4)}-#{display_handle.downcase}@rubygems.org")
      confirm_email!
      disable_totp!
      update_attribute(:password, SecureRandom.alphanumeric)
      update!(
        remember_token: nil,
        remember_token_expires_at: nil,
        api_key: nil,
        blocked_email: original_email
      )
      api_keys.expire_all!
    end
  end

  def unblock!
    raise ArgumentError, "User is not blocked" unless blocked?

    update!(
      email: blocked_email,
      blocked_email: nil
    )
  end

  def blocked?
    blocked_email.present?
  end

  def owns_gem?(rubygem)
    rubygem.owned_by?(self)
  end

  def acknowledge_policies!
    update(policies_acknowledged_at: Time.zone.now)
  end

  def policies_acknowledged?
    policies_acknowledged_at.present?
  end

  private

  def update_email
    update(email: unconfirmed_email, unconfirmed_email: nil, mail_fails: 0)
  end

  def unconfirmed_email_uniqueness
    errors.add(:email, I18n.t("errors.messages.taken")) if unconfirmed_email_exists?
  end

  def unconfirmed_email_exists?
    User.exists?(email: unconfirmed_email)
  end

  def yank_gems
    versions_to_yank = only_owner_gems.map(&:versions).flatten
    versions_to_yank.each do |v|
      deletion = deletions.create(version: v)
      next if deletion.persisted?
      next unless deletion.ineligible?
      deletion.record_yank_forbidden_event!
    end
  end

  def toxic_email_domain
    return unless (domain = email.split("@").last)
    toxic_domains_path = Pathname.new(Gemcutter::Application.config.toxic_domains_filepath)
    toxic = toxic_domains_path.exist? && toxic_domains_path.readlines.grep(/^#{Regexp.escape(domain)}$/).any?

    errors.add(:email, I18n.t("activerecord.errors.messages.blocked", domain: domain)) if toxic
  end

  def password_byte_length
    return if skip_password_validation? || password.blank?
    errors.add(:password, :bcrypt_length) if password.bytesize > 72
  end

  def expire_all_api_keys
    api_keys.expire_all!
  end

  def destroy_associations_for_discard
    ownerships.unscope(where: :confirmed_at).destroy_all
    oidc_pending_trusted_publishers.destroy_all
    subscriptions.destroy_all
    web_hooks.destroy_all
    webauthn_credentials.destroy_all
    webauthn_verification&.destroy!
  end

  def clear_personal_attributes
    @email_before_discard = email
    update!(
      email: "deleted+#{id}@rubygems.org",
      handle: nil, email_confirmed: false,
      unconfirmed_email: nil, blocked_email: nil,
      api_key: nil, confirmation_token: nil, remember_token: nil,
      twitter_username: nil, webauthn_id: nil, full_name: nil,
      totp_seed: nil, mfa_hashed_recovery_codes: nil,
      mfa_level: :disabled,
      password: SecureRandom.hex(20).encode("UTF-8")
    )
  end

  def send_deletion_complete_email
    Mailer.deletion_complete(@email_before_discard).deliver_later
  end

  def record_create_event
    record_event!(Events::UserEvent::CREATED, email:)
  end

  def email_was_updated?
    (saved_change_to_unconfirmed_email? || saved_change_to_email?) &&
      email != attribute_before_last_save(:unconfirmed_email)
  end

  def record_email_update_event
    record_event!(Events::UserEvent::EMAIL_ADDED, email: unconfirmed_email)
  end

  def record_email_verified_event
    record_event!(Events::UserEvent::EMAIL_VERIFIED, email:)
  end

  def record_password_update_event
    record_event!(Events::UserEvent::PASSWORD_CHANGED)
  end

  def unique_with_org_handle
    errors.add(:handle, "has already been taken") if handle && Organization.where("lower(handle) = lower(?)", handle).any?
  end

  def record_policies_acknowledged_event
    record_event!(Events::UserEvent::POLICIES_ACKNOWLEDGED)
  end
end
