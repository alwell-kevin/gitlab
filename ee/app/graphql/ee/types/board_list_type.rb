# frozen_string_literal: true

module EE
  module Types
    module BoardListType
      extend ActiveSupport::Concern

      prepended do
        field :milestone, ::Types::MilestoneType, null: true,
              description: 'Milestone of the list'
        field :max_issue_count, GraphQL::INT_TYPE, null: true,
              description: 'Maximum number of issues in the list'
        field :max_issue_weight, GraphQL::INT_TYPE, null: true,
              description: 'Maximum weight of issues in the list'
        field :assignee, ::Types::UserType, null: true,
              description: 'Assignee in the list'
        field :limit_metric, ::EE::Types::ListLimitMetricEnum, null: true,
              description: 'The current limit metric for the list'

        def milestone
          ::Gitlab::Graphql::Loaders::BatchModelLoader.new(::Milestone, object.milestone_id).find
        end

        def assignee
          object.assignee? ? object.user : nil
        end
      end
    end
  end
end
