# frozen_string_literal: true

require 'spec_helper'

describe GlobalPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe 'reading operations dashboard' do
    context 'when licensed' do
      before do
        stub_licensed_features(operations_dashboard: true)
      end

      it { is_expected.to be_allowed(:read_operations_dashboard) }

      context 'and the user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.not_to be_allowed(:read_operations_dashboard) }
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(operations_dashboard: false)
      end

      it { is_expected.not_to be_allowed(:read_operations_dashboard) }
    end
  end

  it { is_expected.to be_disallowed(:read_licenses) }
  it { is_expected.to be_disallowed(:destroy_licenses) }
  it { is_expected.to be_disallowed(:read_all_geo) }

  it { expect(described_class.new(create(:admin), [user])).to be_allowed(:read_licenses) }
  it { expect(described_class.new(create(:admin), [user])).to be_allowed(:destroy_licenses) }
  it { expect(described_class.new(create(:admin), [user])).to be_allowed(:read_all_geo) }

  shared_examples 'analytics policy' do |action|
    context 'anonymous user' do
      let(:current_user) { nil }

      it 'is not allowed' do
        is_expected.not_to be_allowed(action)
      end
    end

    context 'authenticated user' do
      it 'is allowed' do
        is_expected.to be_allowed(action)
      end
    end
  end

  describe 'view_productivity_analytics' do
    include_examples 'analytics policy', :view_productivity_analytics
  end

  describe 'update_max_pages_size' do
    context 'when feature is enabled' do
      before do
        stub_licensed_features(pages_size_limit: true)
      end

      it { is_expected.to be_disallowed(:update_max_pages_size) }
      it { expect(described_class.new(create(:admin), [user])).to be_allowed(:update_max_pages_size) }
    end

    it { expect(described_class.new(create(:admin), [user])).to be_disallowed(:update_max_pages_size) }
  end

  describe 'create_group_with_default_branch_protection' do
    context 'for an admin' do
      let(:current_user) { create(:admin) }

      context 'when the `default_branch_protection_restriction_in_groups` feature is available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: true)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end
      end

      context 'when the `default_branch_protection_restriction_in_groups` feature is not available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: false)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end
      end
    end

    context 'for a normal user' do
      let(:current_user) { create(:user) }

      context 'when the `default_branch_protection_restriction_in_groups` feature is available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: true)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_disallowed(:create_group_with_default_branch_protection) }
        end
      end

      context 'when the `default_branch_protection_restriction_in_groups` feature is not available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: false)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end
      end
    end
  end
end
