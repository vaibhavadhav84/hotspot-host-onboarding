import 'package:flutter/material.dart';
import '../models/experience_model.dart';
import '../services/api_service.dart';
import '../widgets/experience_card.dart';
import 'onboarding_question_screen.dart';

class ExperienceSelectionScreen extends StatefulWidget {
  const ExperienceSelectionScreen({super.key});

  @override
  State<ExperienceSelectionScreen> createState() =>
      _ExperienceSelectionScreenState();
}

class _ExperienceSelectionScreenState extends State<ExperienceSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _controller = TextEditingController();
  List<Experience> experiences = [];
  Set<int> selectedIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await _apiService.fetchExperiences();
    setState(() {
      experiences = data;
      isLoading = false;
    });
  }

  void toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void onNext() {
    debugPrint("Selected IDs: $selectedIds");
    debugPrint("Text: ${_controller.text}");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingQuestionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101010),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "What kind of hotspots do you want to host?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: experiences.length,
                        itemBuilder: (context, index) {
                          final exp = experiences[index];
                          return ExperienceCard(
                            experience: exp,
                            isSelected: selectedIds.contains(exp.id),
                            onTap: () => toggleSelection(exp.id),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      maxLength: 250,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Describe your perfect hotspot",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xff1b1b1b),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff6169FF),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Next",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
