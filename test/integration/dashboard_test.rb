require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, @user)
    create(:rubygem, name: "arrakis", number: "1.0.0")
  end

  test "request with array of api keys does not pass autorization" do
    delete sign_out_path
    create(:api_key, owner: @user, key: "1234", scopes: %i[show_dashboard])

    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:subscription, rubygem: rubygem, user: @user)

    get "/dashboard.atom?api_key=1234", as: :json

    assert page.has_content? "sandworm"

    get "/dashboard.atom?api_key[]=1234&api_key[]=key1", as: :json

    refute page.has_content? "sandworm"
  end

  test "gems I have pushed show on my dashboard" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:ownership, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    refute page.has_content?("arrakis")
  end

  test "gems I have subscribed to show on my dashboard" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:subscription, rubygem: rubygem, user: @user)

    get dashboard_path

    assert page.has_content? "sandworm"
    refute page.has_content?("arrakis")
  end

  test "organizations are introduced on my dashboard when I belong to one" do
    create(:organization, owners: [@user])

    get dashboard_path

    assert page.has_content? "Introducing Organizations!"
  end

  test "organizations are only introduced when the feature flag is enabled" do
    with_feature(FeatureFlag::ORGANIZATIONS, enabled: false, actor: @user) do
      create(:organization, owners: [@user])

      get dashboard_path

      refute page.has_content? "Introducing Organizations!"
    end
  end

  test "dashboard with a non valid format" do
    assert_raises(ActionController::RoutingError) do
      get dashboard_path(format: :json)
    end
  end

  test "dashboard with atom format" do
    rubygem = create(:rubygem, name: "sandworm", number: "1.0.0")
    create(:subscription, rubygem: rubygem, user: @user)

    get dashboard_path(format: :atom)

    assert_response :success
    assert_equal "application/atom+xml", response.media_type
    assert page.has_content? "sandworm"
  end
end
