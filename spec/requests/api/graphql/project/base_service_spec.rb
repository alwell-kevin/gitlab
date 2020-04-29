# frozen_string_literal: true

require 'spec_helper'

describe 'query Jira service' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:jira_service) { create(:jira_service, project: project) }
  let_it_be(:bugzilla_service) { create(:bugzilla_service, project: project) }
  let_it_be(:redmine_service) { create(:redmine_service, project: project) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          services {
            nodes {
              type
              active
            }
          }
        }
      }
    )
  end

  let(:services) { graphql_data.dig('project', 'services', 'nodes')}

  it_behaves_like 'unauthorized users cannot read services'

  context 'when user can access project services' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'retuns list of jira imports' do
      service_types = services.map { |s| s['type'] }

      expect(service_types).to match_array(%w(BugzillaService JiraService RedmineService))
    end
  end
end
