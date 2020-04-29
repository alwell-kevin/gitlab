# frozen_string_literal: true

require 'spec_helper'

describe 'Admin Dashboard' do
  describe 'Users statistic' do
    let_it_be(:users_statistics) { create(:users_statistics) }

    before do
      sign_in(create(:admin))
    end

    context 'for tooltip' do
      before do
        allow(License).to receive(:current).and_return(license)

        visit admin_dashboard_stats_path
      end

      context 'when license is empty' do
        let(:license) { nil }

        it { expect(page).not_to have_css('span.has-tooltip') }
      end

      context 'when license is on a plan Ultimate' do
        let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

        it { expect(page).to have_css('span.has-tooltip') }
      end

      context 'when license is on a plan other than Ultimate' do
        let(:license) { create(:license, plan: License::PREMIUM_PLAN) }

        it { expect(page).not_to have_css('span.has-tooltip') }
      end
    end

    it 'shows correct amounts of users', :aggregate_failures do
      visit admin_dashboard_stats_path

      expect(page).to have_content("Users without a Group and Project 23")
      expect(page).to have_content("Users with highest role Guest 5")
      expect(page).to have_content("Users with highest role Reporter 9")
      expect(page).to have_content("Users with highest role Developer 21")
      expect(page).to have_content("Users with highest role Maintainer 6")
      expect(page).to have_content("Users with highest role Owner 5")
      expect(page).to have_content("Bots 2")
      expect(page).to have_content("Active users (Billable users) 71")
      expect(page).to have_content("Blocked users 7")
      expect(page).to have_content("Total users 78")
    end
  end
end
