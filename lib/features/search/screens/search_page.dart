import 'package:bloomsplash/features/search/screens/search_default_page.dart';
import 'package:bloomsplash/app/services/firebase/search_db.dart';
import 'package:bloomsplash/app/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import './search_bar.dart' as custom;
import './search_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchProvider _searchProvider = SearchProvider();
  String query = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;
  bool isLoading = false;
  bool hasReachedEnd = false;
  final ScrollController _searchScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, popResult) {
        if (!didPop && isSearching) {
          setState(() {
            isSearching = false;
            query = '';
            searchResults = [];
            isLoading = false;
            hasReachedEnd = false;
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset:false,
        body: SafeArea(
          child: Container(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  custom.SearchBar(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        query = val.trim();
                      });
                    },
                    onSubmitted: (val) async {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty) {
                        setState(() {
                          query = trimmed;
                          isSearching = true;
                          isLoading = true;
                        });
                        _searchController.text = trimmed;
                        List<Map<String, dynamic>> results = await _searchProvider.search(
                          trimmed,
                          (q) async {
                            List<Map<String, dynamic>> r = await SearchDb.searchByColor(q.toLowerCase());
                            if (r.isEmpty) r = await SearchDb.searchByCategory(q.toLowerCase());
                            if (r.isEmpty) r = await SearchDb.searchByTag(q.toLowerCase());
                            if (r.isEmpty) r = await SearchDb.searchAllFields(q, limit: 20);
                            return r;
                          },
                        );
                        setState(() {
                          searchResults = results;
                          isLoading = false;
                          hasReachedEnd = true;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchDetailPage(
                              wallpapers: results,
                              scrollController: _searchScrollController,
                              isLoading: false,
                              hasReachedEnd: true,
                              onRefresh: () async {
                                final refreshed = await _searchProvider.search(
                                  trimmed,
                                  (q) => SearchDb.searchAllFields(q, limit: 20),
                                );
                                setState(() {
                                  searchResults = refreshed;
                                });
                              },
                              result: results.isNotEmpty ? results.first : {},
                              initialQuery: trimmed,
                              controller: _searchController,
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          searchResults = [];
                          isLoading = false;
                          hasReachedEnd = false;
                        });
                      }
                    },
                  ),
                  SearchDefaultPage(
                    onChipTap: (chipLabel, chipType) {
                      setState(() {
                        query = chipLabel;
                        isSearching = true;
                        isLoading = true;
                        _searchController.text = chipLabel;
                      });
                      Future<void>(() async {
                        List<Map<String, dynamic>> results = await _searchProvider.search(
                          chipLabel,
                          (q) async {
                            List<Map<String, dynamic>> r = [];
                            if (chipType == 'Color') {
                              r = await SearchDb.searchByColor(q.toLowerCase());
                            } else if (chipType == 'Category') {
                              r = await SearchDb.searchByCategory(q.toLowerCase());
                            } else if (chipType == 'Tags') {
                              r = await SearchDb.searchByTag(q.toLowerCase());
                            } else {
                              r = await SearchDb.searchAllFields(q, limit: 20);
                            }
                            if (r.isEmpty) {
                              r = await SearchDb.searchAllFields(q, limit: 20);
                            }
                            return r;
                          },
                        );
                        setState(() {
                          searchResults = results;
                          isLoading = false;
                          hasReachedEnd = true;
                        });
                        // Push SearchDetailPage as a new route
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchDetailPage(
                              wallpapers: results,
                              scrollController: _searchScrollController,
                              isLoading: false,
                              hasReachedEnd: true,
                              onRefresh: () async {
                                final refreshed = await _searchProvider.search(
                                  chipLabel,
                                  (q) => SearchDb.searchAllFields(q, limit: 20),
                                );
                                setState(() {
                                  searchResults = refreshed;
                                });
                              },
                              result: results.isNotEmpty ? results.first : {},
                              initialQuery: chipLabel,
                              controller: _searchController,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}