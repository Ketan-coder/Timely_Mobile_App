import 'dart:convert';
import 'dart:io' as io show Directory, File; // Keep for image pasting if used
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path/path.dart' as path; // Keep for image pasting if used
import 'package:http/http.dart' as http;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

// Assuming these are your existing imports
import 'package:timely/auth/auth_service.dart' as auth_service;
import 'package:timely/components/bottom_nav_bar.dart';
import 'package:timely/components/button.dart'; // Assuming you have MyButton
import 'package:timely/components/custom_snack_bar.dart';
import 'package:timely/components/labels.dart'; // Assuming you have MyLabel
import '../components/custom_page_animation.dart'; // From your FAB

class NewAddNotebookPage extends StatefulWidget {
  final int? notebookId;

  const NewAddNotebookPage({super.key, this.notebookId});

  @override
  State<NewAddNotebookPage> createState() => _NewAddNotebookPageState();
}

class _NewAddNotebookPageState extends State<NewAddNotebookPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  late QuillController _quillController;

  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isLoading = false;
  bool _isFetching = false; // For loading state while fetching details

  @override
  void initState() {
    super.initState();
    // Initialize QuillController
    _quillController = QuillController.basic(
      config: QuillControllerConfig(
        // Your existing clipboard config for image pasting
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (kIsWeb) return null;
            final newFileName = 'image-file-${DateTime.now()
                .toIso8601String()}.png';
            final newPath = path.join(
                io.Directory.systemTemp.path, newFileName);
            final file = await io.File(newPath).writeAsBytes(
                imageBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );

    if (widget.notebookId != null) {
      _fetchNotebookDetails(widget.notebookId!);
    } else {
      // Default content for a new note (e.g., an empty document or a placeholder)
      _quillController.document = Document.fromJson([{"insert": "\n"}]);
    }
  }

  Future<void> _fetchNotebookDetails(int notebookId) async {
    setState(() => _isFetching = true);
    try {
      final token = await auth_service.AuthService.getToken();
      if (token == null) {
        showAnimatedSnackBar(
            context, "Authentication token not found.", isError: true,
            isTop: true);
        setState(() => _isFetching = false);
        return;
      }
      final response = await auth_service.AuthService.fetchNotebookDetails(
          token, notebookId);

      if (response != null) {
        _titleController.text = response['title'] ?? '';
        _priorityController.text = response['priority']?.toString() ?? '';

        // Assuming 'body' from backend is plain text for old notes,
        // or JSON string for Quill documents for newer notes.
        // You need to decide how to handle this.
        // If 'body' is ALWAYS plain text from backend:
        final String bodyContent = response['body'] ?? '';
        if (bodyContent.isNotEmpty) {
          // Try to parse as JSON (Quill Delta) first
          try {
            //final decodedBody = jsonDecode(bodyContent);
            final decodedBodyFirst = response['body'] ?? '';
            final decodedBody = HtmlToDelta().convert(
                decodedBodyFirst, transformTableAsEmbed: false);
            _quillController.document = Document.fromJson(
                List<Map<String, dynamic>>.from(decodedBody as Iterable));
          } catch (e) {
            // If parsing fails, assume it's plain text
            _quillController.document = Document()
              ..insert(0, bodyContent);
          }
        } else {
          _quillController.document = Document.fromJson([{"insert": "\n"}]);
        }
      } else {
        showAnimatedSnackBar(
            context, "Failed to fetch notebook details.", isError: true,
            isTop: true);
      }
    } catch (e) {
      showAnimatedSnackBar(
          context, "Error fetching details: ${e.toString()}", isError: true,
          isTop: true);
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _saveOrUpdateNotebook() async {
    // --- Validation ---
    if (_titleController.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Title cannot be Empty", isError: true, isTop: true);
      return;
    }
    if (_priorityController.text.isEmpty) {
      showAnimatedSnackBar(
          context, "Priority cannot be Empty", isError: true, isTop: true);
      return;
    }
    if (_priorityController.text.isNotEmpty) {
      final priority = int.tryParse(_priorityController.text);
      if (priority == null) {
        showAnimatedSnackBar(
            context, "Priority must be a number", isError: true, isTop: true);
        return;
      }
      if (priority < 0 || priority > 5) {
        showAnimatedSnackBar(
            context, "Priority must be between 0 to 5", isError: true,
            isTop: true);
        return;
      }
    }
    if (_quillController.document.isEmpty()) {
      showAnimatedSnackBar(
          context, "Body cannot be Empty", isError: true, isTop: true);
      return;
    }

    setState(() => _isLoading = true);

    final token = await auth_service.AuthService.getToken();
    if (token == null) {
      showAnimatedSnackBar(
          context, "Authentication error. Please log in again.", isError: true,
          isTop: true);
      setState(() => _isLoading = false);
      return;
    }

    // --- Prepare Body Content (Rich Text JSON Delta) ---
    //final String bodyJson = jsonEncode(_quillController.document.toDelta().toJson());
    // If you MUST send plain text to a backend that doesn't support rich text:
    // final String bodyPlainText = _quillController.document.toPlainText();

    //final List<dynamic> delta = _quillController.document.toDelta().toJson();
    //final String richTextContent = delta.map((op) => op['insert']).join();
    //print(richTextContent);

    // Convert Quill Delta to HTML
    final deltaPart = _quillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
      deltaPart, ConverterOptions.forEmail(),);
    final String bodyHtml = converter.convert();

    final Map<String, String> body = {
      'title': _titleController.text,
      'priority': _priorityController.text,
      'body': bodyHtml, // Use bodyJson for rich text
      // 'body': bodyPlainText, // Or use this if backend needs plain text
    };

    http.Response response;
    try {
      if (widget.notebookId != null) {
        // Update existing notebook
        final url = Uri.parse(
            'https://timely.pythonanywhere.com/api/v1/notebooks/${widget
                .notebookId!}/');
        response = await http.patch(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json'
          }, // Ensure correct content type for JSON
          body: jsonEncode(body), // Encode the whole body as JSON
        );
      } else {
        // Add new notebook
        final url = Uri.parse(
            'https://timely.pythonanywhere.com/api/v1/notebooks/');
        response = await http.post(
          url,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json'
          }, // Ensure correct content type for JSON
          body: jsonEncode(body), // Encode the whole body as JSON
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        FocusScope.of(context).unfocus();
        showAnimatedSnackBar(
          context,
          widget.notebookId != null
              ? "Notebook Edited Successfully"
              : "Notebook Added Successfully",
          isSuccess: true,
          isTop: true,
        );
        // Navigate back or to the list page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => const BottomNavBar(currentIndex: 0)),
              (Route<dynamic> route) => false,
        );
      } else {
        String errorMessage = "Something Went Wrong! Status: ${response
            .statusCode}";
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage += "\n${errorBody.toString()}";
        } catch (_) {}
        showAnimatedSnackBar(context, errorMessage, isError: true, isTop: true);
      }
    } catch (e) {
      showAnimatedSnackBar(
          context, "An error occurred: ${e.toString()}", isError: true,
          isTop: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priorityController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use your theme colors
      backgroundColor: Theme
          .of(context)
          .colorScheme
          .inverseSurface, // Or inverseSurface if you prefer
      appBar: AppBar(
        title: Text(
            widget.notebookId != null ? "Edit Notebook" : "Add Notebook"),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .surface,
        // Or inverseSurface
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .onSurface,
        // Or primary
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () { // Disable while loading
          Navigator.of(context).pushReplacement(
              createRoute(const BottomNavBar(currentIndex: 0)));
        },
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .primary,
        foregroundColor: Theme
            .of(context)
            .colorScheme
            .onPrimary,
        child: const Icon(
            Icons.arrow_back), // Or Icons.close, matching old behavior
      ),
      body: SafeArea(
        child: _isFetching
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- Title Field ---
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme
                      .of(context)
                      .colorScheme
                      .onSurface,
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),

              // --- Quill Editor and Toolbar ---
              // Make sure QuillProvider is used if you faced theme issues earlier,
              // or if it's needed for advanced configurations.
              // For simplicity here, I'm directly using them as per your snippet.
              // If you wrap with QuillProvider, ensure controller is passed via provider.
              QuillSimpleToolbar(
                controller: _quillController,
                // Ensure this controller is correctly scoped
                // Re-add your QuillSimpleToolbarConfig from your example
                config: QuillSimpleToolbarConfig( // Updated name
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                    // Updated name
                    showClipboardPaste: true,
                    customButtons: [
                      QuillToolbarCustomButtonOptions(
                        icon: const Icon(Icons.add_alarm_rounded),
                        onPressed: () {
                          _quillController.document.insert(
                            _quillController.selection.extentOffset,
                            TimeStampEmbed(
                              DateTime.now().toString(),
                            ),
                          );

                          _quillController.updateSelection(
                            TextSelection.collapsed(
                              offset: _quillController.selection.extentOffset +
                                  1,
                            ),
                            ChangeSource.local,
                          );
                        },
                      ),
                    ],
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                            afterButtonPressed: () {
                              if (!kIsWeb && (defaultTargetPlatform ==
                                  TargetPlatform.linux ||
                                  defaultTargetPlatform ==
                                      TargetPlatform.windows ||
                                  defaultTargetPlatform ==
                                      TargetPlatform.macOS)) {
                                _editorFocusNode.requestFocus();
                              }
                            }
                        )
                    )
                ),
              ),
              const Divider(),
              Expanded(
                child: QuillEditor(
                  // key: const Key('editor'), // Not strictly necessary unless for specific testing
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  controller: _quillController,
                  // Ensure this controller is correctly scoped
                  config: QuillEditorConfig( // Updated name
                    placeholder: 'Start writing your notes...',
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    // Only vertical, horizontal from main padding
                    // Re-add your embedBuilders config
                    embedBuilders: [
                      ...FlutterQuillEmbeds.editorBuilders(),
                      // Simpler if no custom image/video needed
                      TimeStampEmbedBuilder(),
                      // Keep if used
                    ],
                    // readOnly: false, // default
                  ),
                ),
              ),
              const Divider(),

              // --- Priority Field ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    MyLabel(
                      text: 'Priority:',
                      size: 15, color: Theme
                        .of(context)
                        .colorScheme
                        .surface,
                      // color: Theme.of(context).colorScheme.onSurface // Ensure MyLabel handles color
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Priority (0-5)",
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Save Button ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : MyButton(
                onPressed: _saveOrUpdateNotebook,
                text: widget.notebookId != null
                    ? 'Update Notebook'
                    : 'Add Notebook',
                isGhost: false, // Or as per your styling preference
                margin: 0, // Adjust as needed
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep your TimeStampEmbed and TimeStampEmbedBuilder if you use them
class TimeStampEmbed extends Embeddable {
  const TimeStampEmbed(String value) : super(timeStampType, value);
  static const String timeStampType = 'timeStamp';

  // ... (rest of your TimeStampEmbed class)
  static TimeStampEmbed fromDocument(Document document) =>
      TimeStampEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document => Document.fromJson(jsonDecode(data));
}

class TimeStampEmbedBuilder extends EmbedBuilder {
  @override
  String get key => TimeStampEmbed.timeStampType;

  @override
  String toPlainText(Embed node) => node.value.data;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded),
        Text(embedContext.node.value.data as String),
      ],
    );
  }
}