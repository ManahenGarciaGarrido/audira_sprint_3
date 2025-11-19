// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/faq.dart';
import '../../../core/api/services/faq_service.dart';
import '../../../config/theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final FaqService _faqService = FaqService();
  List<FAQ> _faqs = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  final List<String> _categories = [
    'ALL',
    'ACCOUNT',
    'BILLING',
    'TECHNICAL',
    'ARTISTS',
    'CONTENT',
    'PRIVACY',
    'GENERAL',
  ];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _faqService.getActiveFaqs();
      if (response.success && response.data != null) {
        setState(() {
          _faqs = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load FAQs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFAQsByCategory(String category) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedCategory = category;
    });

    try {
      final response = category == 'ALL'
          ? await _faqService.getActiveFaqs()
          : await _faqService.getFaqsByCategory(category);

      if (response.success && response.data != null) {
        setState(() {
          _faqs = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load FAQs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markFAQAsHelpful(int faqId) async {
    try {
      await _faqService.markAsHelpful(faqId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _markFAQAsNotHelpful(int faqId) async {
    try {
      await _faqService.markAsNotHelpful(faqId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your feedback!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _faqs.isEmpty
                        ? _buildEmptyView()
                        : _buildFAQList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = (_selectedCategory ?? 'ALL') == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _loadFAQsByCategory(category);
                }
              },
              selectedColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedCategory != null && _selectedCategory != 'ALL') {
          await _loadFAQsByCategory(_selectedCategory!);
        } else {
          await _loadFAQs();
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return _buildFAQItem(faq).animate(delay: (index * 50).ms).fadeIn();
          }),
          const SizedBox(height: 24),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            faq.category,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            // Increment view count
            _faqService.incrementViewCount(faq.id);
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.answer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Was this helpful?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _markFAQAsHelpful(faq.id),
                      icon: const Icon(Icons.thumb_up_outlined, size: 16),
                      label: Text('${faq.helpfulCount}'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _markFAQAsNotHelpful(faq.id),
                      icon: const Icon(Icons.thumb_down_outlined, size: 16),
                      label: Text('${faq.notHelpfulCount}'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (faq.viewCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${faq.viewCount} views',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Center(
      child: Column(
        children: [
          const Icon(
            Icons.help_outline,
            size: 48,
            color: AppTheme.textGrey,
          ),
          const SizedBox(height: 16),
          Text(
            '¿No encuentras tu pregunta?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/contact');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Contacta con nosotros'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading FAQs'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFAQs,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.question_answer, size: 64, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          const Text('No FAQs available'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFAQs,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
