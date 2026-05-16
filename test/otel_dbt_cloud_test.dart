// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_dbt_cloud/otel_dbt_cloud.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_dbt_cloud-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('jobs.trigger records job + env + dbt version', () async {
    await tracedDbtCloud<String>(
      operation: 'jobs.trigger',
      invoke: () async => const DbtCloudCallResult(
        value: 'ok',
        result: DbtCloudResult(
          accountId: 'acc_1',
          projectId: 'proj_1',
          environmentId: 'env_1',
          environmentType: 'production',
          jobId: 'job_1',
          jobName: 'daily_full_refresh',
          runId: 'run_1',
          runStatus: 'queued',
          runReason: 'Scheduled',
          dbtVersion: '1.8.4',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('dbt_cloud jobs.trigger')!);
    expect(a['dbt_cloud.job.name'], 'daily_full_refresh');
    expect(a['dbt_cloud.environment.type'], 'production');
    expect(a['dbt_cloud.run.reason'], 'Scheduled');
    expect(a['dbt_cloud.dbt.version'], '1.8.4');
  });

  test('runs.get records test failures (sets span error)', () async {
    await tracedDbtCloud<String>(
      operation: 'runs.get',
      invoke: () async => const DbtCloudCallResult(
        value: 'ok',
        result: DbtCloudResult(
          runId: 'run_2',
          runStatus: 'success',
          modelsExecuted: 145,
          modelsPassed: 145,
          testsExecuted: 320,
          testsPassed: 315,
          testsFailed: 3,
          testsWarn: 2,
          durationSec: 540,
        ),
      ),
    );
    final s = spans.findSpanByName('dbt_cloud runs.get')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['dbt_cloud.tests.failed'], 3);
    expect(attrsOf(s)['dbt_cloud.tests.warn'], 2);
  });

  test('stale sources set span error', () async {
    await tracedDbtCloud<String>(
      operation: 'runs.get',
      invoke: () async => const DbtCloudCallResult(
        value: 'ok',
        result: DbtCloudResult(
          sourcesPassed: 18,
          sourcesStale: 2,
        ),
      ),
    );
    expect(
      spans.findSpanByName('dbt_cloud runs.get')!.status,
      SpanStatusCode.Error,
    );
  });

  test('queued status does NOT set span error', () async {
    await tracedDbtCloud<String>(
      operation: 'runs.get',
      invoke: () async => const DbtCloudCallResult(
        value: 'ok',
        result: DbtCloudResult(runStatus: 'queued'),
      ),
    );
    expect(
      spans.findSpanByName('dbt_cloud runs.get')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutDbtCloudInstrumentationAsync(() async {
      await tracedDbtCloud<String>(
        operation: 'jobs.list',
        invoke: () async => const DbtCloudCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('dbt_cloud '), isEmpty);
  });
}
