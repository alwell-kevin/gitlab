# frozen_string_literal: true

require 'spec_helper'

describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let(:project) { create(:project, :repository, :public) }
  let(:current_user) { create(:user) }
  let(:issues_data) { graphql_data['project']['issues']['edges'] }
  let!(:issues) do
    [create(:issue, project: project, discussion_locked: true),
     create(:issue, project: project)]
  end
  let(:fields) do
    <<~QUERY
    edges {
      node {
        #{all_graphql_fields_for('issues'.classify)}
      }
    }
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', {}, fields)
    )
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: current_user)
    end
  end

  it 'includes a web_url' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['webUrl']).to be_present
  end

  it 'includes discussion locked' do
    post_graphql(query, current_user: current_user)

    expect(issues_data[0]['node']['discussionLocked']).to eq(false)
    expect(issues_data[1]['node']['discussionLocked']).to eq(true)
  end

  context 'when limiting the number of results' do
    let(:query) do
      graphql_query_for(
        'project',
        { 'fullPath' => project.full_path },
        "issues(first: 1) { #{fields} }"
      )
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end

    it 'is expected to check permissions on the first issue only' do
      allow(Ability).to receive(:allowed?).and_call_original
      # Newest first, we only want to see the newest checked
      expect(Ability).not_to receive(:allowed?).with(current_user, :read_issue, issues.first)

      post_graphql(query, current_user: current_user)
    end
  end

  context 'when the user does not have access to the issue' do
    it 'returns nil' do
      project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)

      post_graphql(query)

      expect(issues_data).to eq([])
    end
  end

  context 'when there is a confidential issue' do
    let!(:confidential_issue) do
      create(:issue, :confidential, project: project)
    end

    context 'when the user cannot see confidential issues' do
      it 'returns issues without confidential issues' do
        post_graphql(query, current_user: current_user)

        expect(issues_data.size).to eq(2)

        issues_data.each do |issue|
          expect(issue.dig('node', 'confidential')).to eq(false)
        end
      end
    end

    context 'when the user can see confidential issues' do
      it 'returns issues with confidential issues' do
        project.add_developer(current_user)

        post_graphql(query, current_user: current_user)

        expect(issues_data.size).to eq(3)

        confidentials = issues_data.map do |issue|
          issue.dig('node', 'confidential')
        end

        expect(confidentials).to eq([true, false, false])
      end
    end
  end

  describe 'sorting and pagination' do
    let(:start_cursor) { graphql_data['project']['issues']['pageInfo']['startCursor'] }
    let(:end_cursor) { graphql_data['project']['issues']['pageInfo']['endCursor'] }

    context 'when sorting by due date' do
      let_it_be(:sort_project) { create(:project, :public) }

      let_it_be(:due_issue1) { create(:issue, project: sort_project, due_date: 3.days.from_now) }
      let_it_be(:due_issue2) { create(:issue, project: sort_project, due_date: nil) }
      let_it_be(:due_issue3) { create(:issue, project: sort_project, due_date: 2.days.ago) }
      let_it_be(:due_issue4) { create(:issue, project: sort_project, due_date: nil) }
      let_it_be(:due_issue5) { create(:issue, project: sort_project, due_date: 1.day.ago) }

      let_it_be(:params) { 'sort: DUE_DATE_ASC' }

      def query(issue_params = params)
        graphql_query_for(
          'project',
          { 'fullPath' => sort_project.full_path },
          <<~ISSUES
          issues(#{issue_params}) {
            pageInfo {
              endCursor
            }
            edges {
              node {
                iid
                dueDate
              }
            }
          }
          ISSUES
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      context 'when ascending' do
        it 'sorts issues' do
          expect(grab_iids).to eq([due_issue3.iid, due_issue5.iid, due_issue1.iid, due_issue4.iid, due_issue2.iid])
        end

        context 'when paginating' do
          let(:params) { 'sort: DUE_DATE_ASC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq([due_issue3.iid, due_issue5.iid])

            cursored_query = query("sort: DUE_DATE_ASC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq([due_issue1.iid, due_issue4.iid, due_issue2.iid])
          end
        end
      end

      context 'when descending' do
        let(:params) { 'sort: DUE_DATE_DESC' }

        it 'sorts issues' do
          expect(grab_iids).to eq([due_issue1.iid, due_issue5.iid, due_issue3.iid, due_issue4.iid, due_issue2.iid])
        end

        context 'when paginating' do
          let(:params) { 'sort: DUE_DATE_DESC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq([due_issue1.iid, due_issue5.iid])

            cursored_query = query("sort: DUE_DATE_DESC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq([due_issue3.iid, due_issue4.iid, due_issue2.iid])
          end
        end
      end
    end

    context 'when sorting by relative position' do
      let_it_be(:sort_project) { create(:project, :public) }

      let_it_be(:relative_issue1) { create(:issue, project: sort_project, relative_position: 2000) }
      let_it_be(:relative_issue2) { create(:issue, project: sort_project, relative_position: nil) }
      let_it_be(:relative_issue3) { create(:issue, project: sort_project, relative_position: 1000) }
      let_it_be(:relative_issue4) { create(:issue, project: sort_project, relative_position: nil) }
      let_it_be(:relative_issue5) { create(:issue, project: sort_project, relative_position: 500) }

      let_it_be(:params) { 'sort: RELATIVE_POSITION_ASC' }

      def query(issue_params = params)
        graphql_query_for(
          'project',
          { 'fullPath' => sort_project.full_path },
          "issues(#{issue_params}) { pageInfo { endCursor} edges { node { iid dueDate } } }"
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      context 'when ascending' do
        it 'sorts issues' do
          expect(grab_iids).to eq([relative_issue5.iid, relative_issue3.iid, relative_issue1.iid, relative_issue4.iid, relative_issue2.iid])
        end

        context 'when paginating' do
          let(:params) { 'sort: RELATIVE_POSITION_ASC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq([relative_issue5.iid, relative_issue3.iid])

            cursored_query = query("sort: RELATIVE_POSITION_ASC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq([relative_issue1.iid, relative_issue4.iid, relative_issue2.iid])
          end
        end
      end
    end

    context 'when sorting by priority' do
      let_it_be(:sort_project) { create(:project, :public) }

      let_it_be(:early_milestone) { create(:milestone, project: sort_project, due_date: 10.days.from_now) }
      let_it_be(:late_milestone) { create(:milestone, project: sort_project, due_date: 30.days.from_now) }
      let_it_be(:priority_label1) { create(:label, project: sort_project, priority: 1) }
      let_it_be(:priority_label2) { create(:label, project: sort_project, priority: 5) }
      let_it_be(:priority_issue1) { create(:issue, project: sort_project, labels: [priority_label1], milestone: late_milestone) }
      let_it_be(:priority_issue2) { create(:issue, project: sort_project, labels: [priority_label2]) }
      let_it_be(:priority_issue3) { create(:issue, project: sort_project, milestone: early_milestone) }
      let_it_be(:priority_issue4) { create(:issue, project: sort_project) }

      let_it_be(:params) { 'sort: PRIORITY_ASC' }

      def query(issue_params = params)
        graphql_query_for(
          'project',
          { 'fullPath' => sort_project.full_path },
          "issues(#{issue_params}) { pageInfo { endCursor} edges { node { iid dueDate } } }"
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      context 'when ascending' do
        it 'sorts issues' do
          expect(grab_iids).to eq([priority_issue3.iid, priority_issue1.iid, priority_issue2.iid, priority_issue4.iid])
        end

        context 'when paginating' do
          let(:params) { 'sort: PRIORITY_ASC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq([priority_issue3.iid, priority_issue1.iid])

            cursored_query = query("sort: PRIORITY_ASC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq([priority_issue2.iid, priority_issue4.iid])
          end
        end
      end

      context 'when descending' do
        let(:params) { 'sort: PRIORITY_DESC' }

        it 'sorts issues' do
          expect(grab_iids).to eq([priority_issue1.iid, priority_issue3.iid, priority_issue2.iid, priority_issue4.iid])
        end

        context 'when paginating' do
          let(:params) { 'sort: PRIORITY_DESC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq([priority_issue1.iid, priority_issue3.iid])

            cursored_query = query("sort: PRIORITY_DESC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq([priority_issue2.iid, priority_issue4.iid])
          end
        end
      end
    end

    context 'when sorting by label priority' do
      let_it_be(:sort_project) { create(:project, :public) }

      let_it_be(:label1) { create(:label, project: sort_project, priority: 1) }
      let_it_be(:label2) { create(:label, project: sort_project, priority: 5) }
      let_it_be(:label3) { create(:label, project: sort_project, priority: 10) }
      let_it_be(:label_issue1) { create(:issue, project: sort_project, labels: [label1]) }
      let_it_be(:label_issue2) { create(:issue, project: sort_project, labels: [label2]) }
      let_it_be(:label_issue3) { create(:issue, project: sort_project, labels: [label1, label3]) }
      let_it_be(:label_issue4) { create(:issue, project: sort_project) }

      let_it_be(:params) { 'sort: LABEL_PRIORITY_ASC' }

      def query(issue_params = params)
        graphql_query_for(
          'project',
          { 'fullPath' => sort_project.full_path },
          "issues(#{issue_params}) { pageInfo { endCursor} edges { node { iid dueDate } } }"
        )
      end

      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      context 'when ascending' do
        it 'sorts issues' do
          expect(grab_iids).to eq [label_issue3.iid, label_issue1.iid, label_issue2.iid, label_issue4.iid]
        end

        context 'when paginating' do
          let(:params) { 'sort: LABEL_PRIORITY_ASC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq [label_issue3.iid, label_issue1.iid]

            cursored_query = query("sort: LABEL_PRIORITY_ASC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq [label_issue2.iid, label_issue4.iid]
          end
        end
      end

      context 'when descending' do
        let(:params) { 'sort: LABEL_PRIORITY_DESC' }

        it 'sorts issues' do
          expect(grab_iids).to eq [label_issue2.iid, label_issue3.iid, label_issue1.iid, label_issue4.iid]
        end

        context 'when paginating' do
          let(:params) { 'sort: LABEL_PRIORITY_DESC, first: 2' }

          it 'sorts issues' do
            expect(grab_iids).to eq [label_issue2.iid, label_issue3.iid]

            cursored_query = query("sort: LABEL_PRIORITY_DESC, after: \"#{end_cursor}\"")
            post_graphql(cursored_query, current_user: current_user)
            response_data = JSON.parse(response.body)['data']['project']['issues']['edges']

            expect(grab_iids(response_data)).to eq [label_issue1.iid, label_issue4.iid]
          end
        end
      end
    end
  end

  def grab_iids(data = issues_data)
    data.map do |issue|
      issue.dig('node', 'iid').to_i
    end
  end
end
