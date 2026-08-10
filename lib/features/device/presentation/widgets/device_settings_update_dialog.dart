import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/device_settings_update_provider.dart';
import '../model/device_setting_update.dart';

class DeviceSettingsUpdateDialog extends ConsumerStatefulWidget {
  final String deviceId;
  final List<DeviceSettingUpdate> settings;

  const DeviceSettingsUpdateDialog({
    super.key,
    required this.deviceId,
    required this.settings,
  });

  @override
  ConsumerState<DeviceSettingsUpdateDialog> createState() =>
      _DeviceSettingsUpdateDialogState();
}

class _DeviceSettingsUpdateDialogState
    extends ConsumerState<DeviceSettingsUpdateDialog> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      ref.read(deviceSettingsUpdateNotifierProvider.notifier)
          .updateSettings(
        deviceId: widget.deviceId,
        settings: widget.settings,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // WATCH MQTT SETTINGS UPDATE STATE
    // ==========================================================

    final state = ref.watch(
      deviceSettingsUpdateNotifierProvider,
    );

    final notifier = ref.read(
      deviceSettingsUpdateNotifierProvider.notifier,
    );

    // ==========================================================
    // CHECK FINISHED
    // ==========================================================

    final isFinished =
        state.settings.isNotEmpty &&
            state.settings.every(
                  (setting) =>
              setting.status == SettingUpdateStatus.completed ||
                  setting.status == SettingUpdateStatus.failed,
            );

    // ==========================================================
    // CHECK ALL COMPLETED
    // ==========================================================

    final allCompleted =
        state.settings.isNotEmpty &&
            state.settings.every(
                  (setting) =>
              setting.status == SettingUpdateStatus.completed,
            );

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          minWidth: 520,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [

                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_remote_outlined,
                      color: Colors.blue,
                      size: 25,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          isFinished
                              ? allCompleted
                              ? 'Settings Updated'
                              : 'Settings Update Finished'
                              : 'Updating Device Settings',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Device ID: ${widget.deviceId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close only after process finishes
                  if (isFinished)
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // PROGRESS
              // ==================================================

              _ProgressSection(
                completed: state.completedCount,
                failed: state.failedCount,
                total: state.totalCount,
              ),

              const SizedBox(height: 18),

              // ==================================================
              // STATUS MESSAGE
              // ==================================================

              if (!isFinished)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [

                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Sending settings to device and waiting for acknowledgement...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // FINISHED MESSAGE
              // ==================================================

              if (isFinished)
                _FinishedBanner(
                  allCompleted: allCompleted,
                  completed: state.completedCount,
                  failed: state.failedCount,
                ),

              const SizedBox(height: 18),

              // ==================================================
              // SETTINGS LIST
              // ==================================================

              Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.settings.length,
                    separatorBuilder: (_, __) {
                      return Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      );
                    },
                    itemBuilder: (context, index) {

                      final setting =
                      state.settings[index];

                      return _SettingStatusRow(
                        setting: setting,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // FOOTER
              // ==================================================

              Row(
                mainAxisAlignment:
                MainAxisAlignment.end,
                children: [

                  // CANCEL WHILE UPDATING
                  if (!isFinished)
                    OutlinedButton(
                      onPressed: () {

                        notifier.cancel();

                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),

                  // DONE AFTER COMPLETION
                  if (isFinished)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Done',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// PROGRESS SECTION
// ============================================================

class _ProgressSection extends StatelessWidget {
  final int completed;
  final int failed;
  final int total;

  const _ProgressSection({
    required this.completed,
    required this.failed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {

    final finished =
        completed + failed;

    final progress = total == 0
        ? 0.0
        : finished / total;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [

        Row(
          children: [

            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Text(
              '$finished / $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 9),

        ClipRRect(
          borderRadius:
          BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor:
            Colors.grey.shade200,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [

            _CountItem(
              icon: Icons.check_circle,
              label: '$completed Completed',
              iconColor: Colors.green,
            ),

            const SizedBox(width: 18),

            _CountItem(
              icon: Icons.error,
              label: '$failed Failed',
              iconColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}


// ============================================================
// COUNT ITEM
// ============================================================

class _CountItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _CountItem({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [

        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),

        const SizedBox(width: 5),

        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}


// ============================================================
// SETTING STATUS ROW
// ============================================================

class _SettingStatusRow extends StatelessWidget {
  final DeviceSettingUpdate setting;

  const _SettingStatusRow({
    required this.setting,
  });

  @override
  Widget build(BuildContext context) {

    final statusInfo =
    _getStatusInfo(setting.status);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      child: Row(
        children: [

          // ==================================================
          // STATUS ICON
          // ==================================================

          SizedBox(
            width: 38,
            child: Center(
              child: statusInfo.isLoading

                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                ),
              )

                  : Icon(
                statusInfo.icon,
                size: 21,
                color: statusInfo.color,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // SETTING INFORMATION
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  setting.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  setting.value,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),

                // ==================================================
                // ERROR
                // ==================================================

                if (setting.status ==
                    SettingUpdateStatus.failed &&
                    setting.error != null) ...[

                  const SizedBox(height: 5),

                  Text(
                    setting.error!,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // STATUS CHIP
          // ==================================================

          _StatusChip(
            text: statusInfo.label,
            color: statusInfo.color,
          ),
        ],
      ),
    );
  }
}


// ============================================================
// STATUS CHIP
// ============================================================

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


// ============================================================
// FINISHED BANNER
// ============================================================

class _FinishedBanner extends StatelessWidget {
  final bool allCompleted;
  final int completed;
  final int failed;

  const _FinishedBanner({
    required this.allCompleted,
    required this.completed,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {

    final color =
    allCompleted
        ? Colors.green
        : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [

          Icon(
            allCompleted
                ? Icons.check_circle
                : Icons.warning_rounded,
            color: color,
            size: 22,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              allCompleted
                  ? 'All $completed settings were successfully acknowledged by the device.'
                  : '$completed settings completed and $failed settings failed.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// STATUS INFO
// ============================================================

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });
}


// ============================================================
// GET STATUS INFO
// ============================================================

_StatusInfo _getStatusInfo(
    SettingUpdateStatus status,
    ) {

  switch (status) {

    case SettingUpdateStatus.pending:
      return const _StatusInfo(
        label: 'Pending',
        icon:
        Icons.radio_button_unchecked,
        color: Colors.grey,
      );

    case SettingUpdateStatus.sending:
      return const _StatusInfo(
        label: 'Sending...',
        icon: Icons.sync,
        color: Colors.blue,
        isLoading: true,
      );

    case SettingUpdateStatus.completed:
      return const _StatusInfo(
        label: 'Completed',
        icon: Icons.check_circle,
        color: Colors.green,
      );

    case SettingUpdateStatus.failed:
      return const _StatusInfo(
        label: 'Failed',
        icon: Icons.cancel,
        color: Colors.red,
      );
  }
}