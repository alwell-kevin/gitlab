# frozen_string_literal: true

module EE
  module Types
    module MutationType
      extend ActiveSupport::Concern

      prepended do
        mount_mutation ::Mutations::DesignManagement::Upload, calls_gitaly: true
        mount_mutation ::Mutations::DesignManagement::Delete, calls_gitaly: true
        mount_mutation ::Mutations::Issues::SetWeight
        mount_mutation ::Mutations::EpicTree::Reorder
        mount_mutation ::Mutations::Epics::Update
        mount_mutation ::Mutations::Epics::Create
        mount_mutation ::Mutations::Epics::SetSubscription
        mount_mutation ::Mutations::Epics::AddIssue
        mount_mutation ::Mutations::Requirements::Create
        mount_mutation ::Mutations::Requirements::Update
        mount_mutation ::Mutations::Vulnerabilities::Dismiss
        mount_mutation ::Mutations::Boards::Lists::UpdateLimitMetrics
        mount_mutation ::Mutations::SecurityDashboard::AddProjects
      end
    end
  end
end
