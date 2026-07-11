import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/models/model_info.dart';

class ModelSelectionWidget extends StatefulWidget {
  final ChatCatalogReady catalogState;

  const ModelSelectionWidget({super.key, required this.catalogState});

  @override
  State<ModelSelectionWidget> createState() => _ModelSelectionWidgetState();
}

class _ModelSelectionWidgetState extends State<ModelSelectionWidget> {
  final Map<String, PreferredBackend> _localBackends = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = widget.catalogState;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select On-Device LLM',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an accelerated local model to run offline directly on your NPU/GPU.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF64748B),
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: state.models.length,
              itemBuilder: (context, index) {
                final model = state.models[index];
                final isInstalled = state.installationStatus[model.id] ?? false;
                final isLoader = state.loadingStates[model.id] ?? false;
                
                // Initialize local backend selection if not present
                _localBackends[model.id] ??= state.selectedBackends[model.id] ?? PreferredBackend.gpu;
                final selectedBackend = _localBackends[model.id]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        model.name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF383552) : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          model.sizeLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF0F52FF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    model.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFA7A9BE) : const Color(0xFF475569),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Backend:',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<PreferredBackend>(
                                  value: selectedBackend,
                                  underline: const SizedBox(),
                                  style: GoogleFonts.inter(fontSize: 13, color: theme.primaryColor, fontWeight: FontWeight.w600),
                                  items: const [
                                    DropdownMenuItem(value: PreferredBackend.gpu, child: Text('GPU (OpenCL)')),
                                    DropdownMenuItem(value: PreferredBackend.npu, child: Text('NPU (QNN/DSP)')),
                                    DropdownMenuItem(value: PreferredBackend.cpu, child: Text('CPU (Fallback)')),
                                  ],
                                  onChanged: (backend) {
                                    if (backend != null) {
                                      setState(() {
                                        _localBackends[model.id] = backend;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isInstalled) ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: isLoader ? null : () {
                                      context.read<ChatBloc>().add(ChatActivateModel(
                                        model: model,
                                        backend: selectedBackend,
                                      ));
                                    },
                                    child: isLoader
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text('Activate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ] else ...[
                                  TextButton.icon(
                                    icon: const Icon(Icons.download_rounded, size: 16),
                                    label: Text('Sideload', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () => _showSideloadInstructions(context, model),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0),
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: isLoader ? null : () {
                                      context.read<ChatBloc>().add(ChatDownloadModel(model: model));
                                    },
                                    child: isLoader
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Text('Download', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSideloadInstructions(BuildContext context, ModelInfo model) {
    const packageName = 'com.example.code_card_ai';
    final filename = model.filename;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1C2A) : Colors.white,
          title: Row(
            children: [
              Icon(Icons.terminal_rounded, color: theme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'ADB Sideload Walkthrough',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To bypass slow downloads over the network, you can copy the model directly from your PC via ADB:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                _buildCodeBox(
                  context,
                  'Step 1: Push file to device temp folder\n'
                  'adb push path/to/$filename /data/local/tmp/$filename',
                ),
                const SizedBox(height: 10),
                _buildCodeBox(
                  context,
                  'Step 2: Copy file into app sandbox via run-as\n'
                  'adb shell "run-as $packageName cp /data/local/tmp/$filename /data/user/0/$packageName/app_flutter/"',
                ),
                const SizedBox(height: 10),
                _buildCodeBox(
                  context,
                  'Step 3: Verify copy succeeded\n'
                  'adb shell "run-as $packageName ls -lh /data/user/0/$packageName/app_flutter/"',
                ),
                const SizedBox(height: 10),
                _buildCodeBox(
                  context,
                  'Step 4: Clean up temp file\n'
                  'adb shell rm -f /data/local/tmp/$filename',
                ),
                const SizedBox(height: 14),
                Text(
                  'Once completed, restart the app and this model will instantly show as "Ready".',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: theme.primaryColor),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCodeBox(BuildContext context, String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF383552) : const Color(0xFFE2E8F0)),
      ),
      child: Stack(
        children: [
          SelectableText(
            code,
            style: GoogleFonts.firaCode(fontSize: 11, height: 1.4),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Command copied to clipboard')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
