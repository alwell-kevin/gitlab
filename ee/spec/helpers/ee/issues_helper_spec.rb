# frozen_string_literal: true

require "spec_helper"

describe EE::IssuesHelper do
  let(:project) { create(:project) }
  let(:issue) { create :issue, project: project }

  describe '#issue_closed_link' do
    let(:new_epic) { create(:epic) }
    let(:user)     { create(:user) }

    context 'with linked issue' do
      context 'with promoted issue' do
        before do
          issue.update(promoted_to_epic: new_epic)
        end

        context 'when user has permission to see new epic' do
          before do
            expect(helper).to receive(:can?).with(user, :read_epic, new_epic) { true }
          end

          let(:css_class) { 'text-white text-underline' }

          it 'returns link' do
            link = "<a class=\"#{css_class}\" href=\"/groups/#{new_epic.group.full_path}/-/epics/#{new_epic.iid}\">(promoted)</a>"

            expect(helper.issue_closed_link(issue, user, css_class: css_class)).to match(link)
          end
        end

        context 'when user has no permission to see new epic' do
          before do
            expect(helper).to receive(:can?).with(user, :read_epic, new_epic) { false }
          end

          it 'returns nil' do
            expect(helper.issue_closed_link(issue, user)).to be_nil
          end
        end
      end
    end
  end

  describe '#issue_in_subepic?' do
    let_it_be(:epic) { create(:epic) }
    let_it_be(:epic_issue) { create(:epic_issue, epic: epic) }
    let(:issue) { build_stubbed(:issue, epic_issue: epic_issue) }
    let(:new_issue) { build_stubbed(:issue) }

    it 'returns false if epic_id parameter is not set or is wildcard' do
      ['', nil, 'none', 'any'].each do |epic_id|
        expect(helper.issue_in_subepic?(issue, epic_id)).to be_falsy
      end
    end

    it 'returns false if epic_id parameter is the same as issue epic_id' do
      expect(helper.issue_in_subepic?(issue, epic.id)).to be_falsy
    end

    it 'returns false if the issue is not part of an epic' do
      expect(helper.issue_in_subepic?(new_issue, epic.id)).to be_falsy
    end

    it 'returns true if epic_id parameter is not the same as issue epic_id' do
      # When issue_in_subepic? is used, any epic with a different
      # id than the one on the params is considered a child
      expect(helper.issue_in_subepic?(issue, 'subepic_id')).to be_truthy
    end
  end

  describe '#show_moved_service_desk_issue_warning?' do
    let(:project1) { create(:project, service_desk_enabled: true) }
    let(:project2) { create(:project, service_desk_enabled: true) }
    let!(:old_issue) { create(:issue, author: User.support_bot, project: project1) }
    let!(:new_issue) { create(:issue, author: User.support_bot, project: project2) }

    before do
      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      old_issue.update(moved_to: new_issue)
    end

    it 'is true when moved issue project has service desk disabled' do
      project2.update!(service_desk_enabled: false)

      expect(helper.show_moved_service_desk_issue_warning?(new_issue)).to be(true)
    end

    it 'is false when moved issue project has service desk enabled' do
      expect(helper.show_moved_service_desk_issue_warning?(new_issue)).to be(false)
    end
  end
end
