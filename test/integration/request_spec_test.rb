# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../integration_helper"

describe "typical request spec" do
  it "converts describe/let!/eq and leaves request helpers and unsupported matchers" do
    source = <<~RUBY
      require "rails_helper"

      RSpec.describe "Sessions", type: :request do
        describe "POST /session" do
          let(:password) { "secret" }
          let!(:user) { create(:user, password: password) }

          it "redirects to the dashboard" do
            post session_path, params: { email: user.email, password: password }

            expect(response).to redirect_to(dashboard_path)
            expect(session[:user_id]).to eq(user.id)
          end

          it "rejects bad credentials" do
            post session_path, params: { email: user.email, password: "wrong" }

            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    RUBY

    expected = <<~RUBY
      require "rails_helper"

      describe "Sessions", type: :request do
        describe "POST /session" do
          let(:password) { "secret" }
          let(:user) { create(:user, password: password) }
          before { user }

          it "redirects to the dashboard" do
            post session_path, params: { email: user.email, password: password }

            expect(response).to redirect_to(dashboard_path)
            expect(session[:user_id]).must_equal user.id
          end

          it "rejects bad credentials" do
            post session_path, params: { email: user.email, password: "wrong" }

            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    RUBY

    assert_converts source, expected, path: "spec/requests/sessions_spec.rb"
  end
end
