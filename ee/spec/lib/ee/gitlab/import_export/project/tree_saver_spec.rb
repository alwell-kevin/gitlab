# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Project::TreeSaver do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:shared) { project.import_export_shared }

  let_it_be(:design) { create(:design, :with_file, versions_count: 2, issue: issue) }
  let_it_be(:note) { create(:diff_note_on_design, noteable: design, project: project, author: user) }
  let_it_be(:note2) { create(:note, noteable: issue, project: project, author: user) }

  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic_issue) { create(:epic_issue, issue: issue, epic: epic) }

  let_it_be(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec_ee" }

  after :all do
    FileUtils.rm_rf(export_path)
  end

  shared_examples 'EE saves project tree successfully' do |ndjson_enabled|
    include ::ImportExport::CommonUtil

    let_it_be(:project_tree_saver) { described_class.new(project: project, current_user: user, shared: shared) }

    let_it_be(:full_path) do
      if ndjson_enabled
        File.join(shared.export_path, 'tree')
      else
        File.join(shared.export_path, Gitlab::ImportExport.project_filename)
      end
    end

    let_it_be(:exportable_path) { 'project' }

    before_all do
      Feature.enable(:project_export_as_ndjson) if ndjson_enabled
      project.add_maintainer(user)
      expect(project_tree_saver.save).to be true
    end

    let_it_be(:issue_json) { get_json(full_path, exportable_path, :issues, ndjson_enabled).first }

    describe 'the designs json' do
      it 'saves issue.designs correctly' do
        expect(issue_json['designs'].size).to eq(1)
      end

      it 'saves issue.design_versions correctly' do
        actions = issue_json['design_versions'].flat_map { |v| v['actions'] }

        expect(issue_json['design_versions'].size).to eq(2)
        issue_json['design_versions'].each do |version|
          expect(version['author_id']).to eq(issue.author_id)
        end
        expect(actions.size).to eq(2)
        actions.each do |action|
          expect(action['design']).to be_present
        end
      end
    end

    context 'epics' do
      it 'has epic_issue' do
        expect(issue_json['epic_issue']).not_to be_empty
        expect(issue_json['epic_issue']['id']).to eql(epic_issue.id)
      end

      it 'has epic' do
        expect(issue_json['epic_issue']['epic']['title']).to eql(epic.title)
      end

      it 'does not have epic_id' do
        expect(issue_json['epic_issue']['epic_id']).to be_nil
      end

      it 'does not have issue_id' do
        expect(issue_json['epic_issue']['issue_id']).to be_nil
      end
    end
  end

  context 'with JSON' do
    it_behaves_like "EE saves project tree successfully", false
  end

  context 'with NDJSON' do
    it_behaves_like "EE saves project tree successfully", true
  end
end
