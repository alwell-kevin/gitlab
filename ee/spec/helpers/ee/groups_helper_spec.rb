# frozen_string_literal: true

require 'spec_helper'

describe GroupsHelper do
  using RSpec::Parameterized::TableSyntax

  let(:owner) { create(:user, group_view: :security_dashboard) }
  let(:current_user) { owner }
  let(:group) { create(:group, :private) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    helper.instance_variable_set(:@group, group)

    group.add_owner(owner)
  end

  describe '#group_epics_count' do
    before do
      stub_licensed_features(epics: true)

      create_list(:epic, 3, :opened, group: group)
      create_list(:epic, 2, :closed, group: group)
    end

    it 'returns open epics count' do
      expect(helper.group_epics_count(state: 'opened')).to eq(3)
    end

    it 'returns closed epics count' do
      expect(helper.group_epics_count(state: 'closed')).to eq(2)
    end
  end

  describe '#group_sidebar_links' do
    before do
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
      allow(helper).to receive(:show_promotions?) { false }
    end

    it 'shows the licensed features when they are available' do
      stub_licensed_features(contribution_analytics: true,
                             epics: true)

      expect(helper.group_sidebar_links).to include(:contribution_analytics, :epics)
    end

    it 'hides the licensed features when they are not available' do
      stub_licensed_features(contribution_analytics: false,
                             epics: false)

      expect(helper.group_sidebar_links).not_to include(:contribution_analytics, :epics)
    end

    context 'when contribution analytics is available' do
      before do
        stub_licensed_features(contribution_analytics: true)
      end

      context 'signed in user is a project member but not a member of the group' do
        let(:current_user) { create(:user) }
        let(:private_project) { create(:project, :private, group: group)}

        it 'hides Contribution Analytics' do
          expect(helper.group_sidebar_links).not_to include(:contribution_analytics)
        end
      end
    end
  end

  describe '#permanent_deletion_date' do
    let(:date) { 2.days.from_now }

    subject { helper.permanent_deletion_date(date) }

    before do
      stub_application_setting(deletion_adjourned_period: 5)
    end

    it 'returns the sum of the date passed as argument and the deletion_adjourned_period set in application setting' do
      expected_date = date + 5.days

      expect(subject).to eq(expected_date.strftime('%F'))
    end
  end

  describe '#remove_group_message' do
    subject { helper.remove_group_message(group) }

    context 'adjourned deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      it 'returns the message related to adjourned deletion' do
        expect(subject).to include("The contents of this group, its subgroups and projects will be permanently removed after")
      end
    end

    context 'adjourned deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      it 'returns the message related to permanent deletion' do
        expect(subject).to include("You are going to remove #{group.name}")
        expect(subject).to include("Removed groups CANNOT be restored!")
      end
    end
  end

  describe '#show_discover_group_security?' do
    using RSpec::Parameterized::TableSyntax

    where(
      ab_feature_enabled?: [true, false],
      gitlab_com?: [true, false],
      user?: [true, false],
      created_at: [Time.mktime(2010, 1, 20), Time.mktime(2030, 1, 20)],
      discover_security_feature_enabled?: [true, false],
      security_dashboard_feature_available?: [true, false],
      can_admin_group?: [true, false]
    )

    with_them do
      it 'returns the expected value' do
        allow(helper).to receive(:current_user) { user? ? owner : nil }
        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(owner).to receive(:ab_feature_enabled?) { ab_feature_enabled? }
        allow(owner).to receive(:created_at) { created_at }
        allow(::Feature).to receive(:enabled?).with(:discover_security) { discover_security_feature_enabled? }
        allow(group).to receive(:feature_available?) { security_dashboard_feature_available? }
        allow(helper).to receive(:can?) { can_admin_group? }

        expected_value = user? && created_at > DateTime.new(2019, 11, 1) && gitlab_com? &&
                         ab_feature_enabled? && !security_dashboard_feature_available? && can_admin_group?

        expect(helper.show_discover_group_security?(group)).to eq(expected_value)
      end
    end
  end

  describe '#show_group_activity_analytics?' do
    before do
      allow(Feature).to receive(:enabled?).with(:group_activity_analytics, group).and_return(false)
      allow(Feature).to receive(:enabled?).with(:group_activity_analytics).and_return(true)

      stub_licensed_features(group_activity_analytics: feature_available)

      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
    end

    context 'when feature is not available for group' do
      let(:feature_available) { false }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when current user does not have access to the group' do
      let(:feature_available) { true }
      let(:current_user) { create(:user) }

      it 'returns false' do
        expect(helper.show_group_activity_analytics?).to be false
      end
    end

    context 'when feature is available and user has access to it' do
      let(:feature_available) { true }

      it 'returns true' do
        expect(helper.show_group_activity_analytics?).to be true
      end
    end
  end

  describe '#show_usage_quotas_in_sidebar?' do
    where(:usage_quotas_feature_available?, :expected) do
      true  | true
      false | false
    end

    with_them do
      it do
        stub_licensed_features(usage_quotas: usage_quotas_feature_available?)

        expect(helper.show_usage_quotas_in_sidebar?).to eq(expected)
      end
    end
  end

  describe '#show_billing_in_sidebar?' do
    where(:should_check_namespace_plan_return_value, :expected) do
      true  | true
      false | false
    end

    with_them do
      it do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(should_check_namespace_plan_return_value)

        expect(helper.show_billing_in_sidebar?).to eq(expected)
      end
    end
  end

  describe '#show_administration_nav?' do
    context 'when user does not have admin_group permissions' do
      before do
        allow(helper).to receive(:can?).and_return(true)
        allow(helper).to receive(:can?).with(current_user, :admin_group, group).and_return(false)
      end

      it 'returns false' do
        expect(helper.show_administration_nav?(group)).to be false
      end
    end

    context 'when user has admin_group permissions' do
      before do
        allow(helper).to receive(:can?).and_return(false)
        allow(helper).to receive(:can?).with(current_user, :admin_group, group).and_return(true)
      end

      it 'returns true' do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(true)

        expect(helper.show_administration_nav?(group)).to be true
      end

      it 'returns false for a subgroup' do
        subgroup = create(:group, :private, parent: group)

        expect(helper.show_administration_nav?(subgroup)).to be false
      end

      context 'when `group_administration_nav_item` feature flag is disabled for the group' do
        before do
          stub_feature_flags(group_administration_nav_item: { enabled: false, thing: group })
        end

        it 'returns false' do
          expect(helper.show_administration_nav?(group)).to be false
        end
      end
    end
  end

  describe '#administration_nav_path' do
    context 'when SAML providers feature is available' do
      before do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(true)
      end

      it 'returns path to SAML providers' do
        expect(helper.administration_nav_path(group)).to eq(group_saml_providers_path(group))
      end
    end

    context 'when SAML providers feature is not available' do
      before do
        allow(helper).to receive(:show_saml_in_sidebar?).with(group).and_return(false)
      end

      context 'and usage quotas feature is available' do
        before do
          allow(helper).to receive(:show_usage_quotas_in_sidebar?).and_return(true)
        end

        it 'returns path to usage quotas' do
          expect(helper.administration_nav_path(group)).to eq(group_usage_quotas_path(group))
        end
      end

      context 'and usage quotas feature is not available' do
        before do
          allow(helper).to receive(:show_usage_quotas_in_sidebar?).and_return(false)
        end

        context 'and billing feature is available' do
          before do
            allow(helper).to receive(:show_billing_in_sidebar?).and_return(true)
          end

          it 'returns path to billing' do
            expect(helper.administration_nav_path(group)).to eq(group_billings_path(group))
          end
        end
      end
    end
  end
end
