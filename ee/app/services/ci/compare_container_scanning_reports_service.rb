# frozen_string_literal: true

module Ci
  class CompareContainerScanningReportsService < ::Ci::CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer
    end

    def serializer_class
      Vulnerabilities::OccurrenceDiffSerializer
    end

    def get_report(pipeline)
      Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: { report_type: %w[container_scanning], scope: 'all' }).execute
    end

    def build_comparer(base_pipeline, head_pipeline)
      comparer_class.new(get_report(base_pipeline), get_report(head_pipeline), head_security_scans: head_pipeline.security_scans)
    end
  end
end
