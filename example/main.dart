// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_dbt_cloud/otel_dbt_cloud.dart';

/// Traces dbt Cloud calls with OpenTelemetry.
///
/// `otel_dbt_cloud` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each dbt Cloud call in
/// [tracedDbtCloud]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'dbt-cloud-example');

  // Wraps a dbt Cloud API call in a CLIENT span.
  final dbtCloudId = await tracedDbtCloud<String>(
    operation: 'environments.create',
    invoke: () async {
      // Make the dbt Cloud call here, then report what it returned.
      const id = 'dbt_cloud_8f3a2c';
      return const DbtCloudCallResult(
          value: id,
          result: DbtCloudResult(
              accountId: 'account_8f3a2c',
              projectId: 'project_8f3a2c',
              environmentId: 'environment_8f3a2c',
              environmentType: 'development',
              jobId: 'job_8f3a2c',
              jobName: 'example',
              runId: 'run_8f3a2c',
              runStatus: 'queued',
              runReason: 'Scheduled',
              dbtVersion: '1',
              modelsExecuted: 1,
              modelsPassed: 1,
              testsExecuted: 1,
              testsPassed: 1,
              testsFailed: 1,
              testsWarn: 1,
              snapshotsRun: 1,
              sourcesPassed: 1,
              sourcesStale: 1,
              deferToRunId: 'defertorun_8f3a2c',
              durationSec: 120,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedDbtCloud environments.create returned $dbtCloudId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutDbtCloudInstrumentationAsync.
  await runWithoutDbtCloudInstrumentationAsync(
    () => tracedDbtCloud<String>(
      operation: 'environments.create',
      invoke: () async {
        const id = 'dbt_cloud_8f3a2c';
        return const DbtCloudCallResult(
            value: id,
            result: DbtCloudResult(
                accountId: 'account_8f3a2c',
                projectId: 'project_8f3a2c',
                environmentId: 'environment_8f3a2c',
                environmentType: 'development',
                jobId: 'job_8f3a2c',
                jobName: 'example',
                runId: 'run_8f3a2c',
                runStatus: 'queued',
                runReason: 'Scheduled',
                dbtVersion: '1',
                modelsExecuted: 1,
                modelsPassed: 1,
                testsExecuted: 1,
                testsPassed: 1,
                testsFailed: 1,
                testsWarn: 1,
                snapshotsRun: 1,
                sourcesPassed: 1,
                sourcesStale: 1,
                deferToRunId: 'defertorun_8f3a2c',
                durationSec: 120,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
