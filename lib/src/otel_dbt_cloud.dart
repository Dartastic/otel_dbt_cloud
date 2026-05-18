// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_dbt_cloud_suppression.dart';

const _tracerName = 'dartastic_otel_libs_dbt_cloud';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class DbtCloudResult {
  const DbtCloudResult({
    this.accountId,
    this.projectId,
    this.environmentId,
    this.environmentType,
    this.jobId,
    this.jobName,
    this.runId,
    this.runStatus,
    this.runReason,
    this.dbtVersion,
    this.modelsExecuted,
    this.modelsPassed,
    this.testsExecuted,
    this.testsPassed,
    this.testsFailed,
    this.testsWarn,
    this.snapshotsRun,
    this.sourcesPassed,
    this.sourcesStale,
    this.deferToRunId,
    this.durationSec,
    this.statusCode,
  });

  final String? accountId;
  final String? projectId;
  final String? environmentId;

  /// `development` / `staging` / `production`.
  final String? environmentType;

  final String? jobId;
  final String? jobName;
  final String? runId;

  /// `queued` / `starting` / `running` / `success` / `error` /
  /// `cancelled`. dbt encodes these as ints in v2 but we surface the
  /// string for readability.
  final String? runStatus;

  /// `Scheduled` / `Github Pull Request` / `Other` / `Triggered via
  /// API` / `Triggered via webhook` — what kicked the run off.
  final String? runReason;

  /// dbt-core version compiled into the run.
  final String? dbtVersion;

  /// Model execution breakdown.
  final int? modelsExecuted;
  final int? modelsPassed;

  /// Test execution breakdown.
  final int? testsExecuted;
  final int? testsPassed;
  final int? testsFailed;
  final int? testsWarn;

  final int? snapshotsRun;

  /// Source freshness checks.
  final int? sourcesPassed;
  final int? sourcesStale;

  /// dbt's defer-to-prod artifact source for slim CI.
  final String? deferToRunId;

  final int? durationSec;
  final int? statusCode;
}

class DbtCloudCallResult<T> {
  const DbtCloudCallResult({required this.value, this.result});
  final T value;
  final DbtCloudResult? result;
}

/// Wraps a dbt Cloud API call in a CLIENT span. [operation] is one of
/// `jobs.list`, `jobs.get`, `jobs.trigger`, `runs.list`,
/// `runs.get`, `runs.cancel`, `runs.artifacts.list`,
/// `runs.artifacts.get`, `projects.list`, `environments.list`,
/// `environments.create`, `accounts.get`, `discovery.query`.
Future<T> tracedDbtCloud<T>({
  required String operation,
  required Future<DbtCloudCallResult<T>> Function() invoke,
}) async {
  if (dbtCloudInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'dbt_cloud',
    'rpc.method': operation,
    'dbt_cloud.operation': operation,
  };

  final span = _tracer().startSpan(
    'dbt_cloud $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.accountId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.account.id',
          r.result!.accountId!,
        ));
      }
      if (r.result!.projectId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.project.id',
          r.result!.projectId!,
        ));
      }
      if (r.result!.environmentId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.environment.id',
          r.result!.environmentId!,
        ));
      }
      if (r.result!.environmentType != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.environment.type',
          r.result!.environmentType!,
        ));
      }
      if (r.result!.jobId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.job.id',
          r.result!.jobId!,
        ));
      }
      if (r.result!.jobName != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.job.name',
          r.result!.jobName!,
        ));
      }
      if (r.result!.runId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.run.id',
          r.result!.runId!,
        ));
      }
      if (r.result!.runStatus != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.run.status',
          r.result!.runStatus!,
        ));
        if (r.result!.runStatus == 'error') {
          span.setStatus(SpanStatusCode.Error, 'dbt Cloud run error');
        }
      }
      if (r.result!.runReason != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.run.reason',
          r.result!.runReason!,
        ));
      }
      if (r.result!.dbtVersion != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.dbt.version',
          r.result!.dbtVersion!,
        ));
      }
      if (r.result!.modelsExecuted != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.models.executed',
          r.result!.modelsExecuted!,
        ));
      }
      if (r.result!.modelsPassed != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.models.passed',
          r.result!.modelsPassed!,
        ));
      }
      if (r.result!.testsExecuted != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.tests.executed',
          r.result!.testsExecuted!,
        ));
      }
      if (r.result!.testsPassed != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.tests.passed',
          r.result!.testsPassed!,
        ));
      }
      if (r.result!.testsFailed != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.tests.failed',
          r.result!.testsFailed!,
        ));
        if (r.result!.testsFailed! > 0) {
          span.setStatus(SpanStatusCode.Error, 'dbt Cloud tests failed');
        }
      }
      if (r.result!.testsWarn != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.tests.warn',
          r.result!.testsWarn!,
        ));
      }
      if (r.result!.snapshotsRun != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.snapshots.run',
          r.result!.snapshotsRun!,
        ));
      }
      if (r.result!.sourcesPassed != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.sources.passed',
          r.result!.sourcesPassed!,
        ));
      }
      if (r.result!.sourcesStale != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.sources.stale',
          r.result!.sourcesStale!,
        ));
        if (r.result!.sourcesStale! > 0) {
          span.setStatus(SpanStatusCode.Error, 'dbt Cloud sources stale');
        }
      }
      if (r.result!.deferToRunId != null) {
        extras.add(OTel.attributeString(
          'dbt_cloud.defer.to_run_id',
          r.result!.deferToRunId!,
        ));
      }
      if (r.result!.durationSec != null) {
        extras.add(OTel.attributeInt(
          'dbt_cloud.duration_sec',
          r.result!.durationSec!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'dbt Cloud HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
