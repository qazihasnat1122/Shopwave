import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/product/product_bloc.dart';
import '../../utils/app_theme.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _sortBy;
  double? _minPrice, _maxPrice;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search() {
    context.read<ProductBloc>().add(ProductsLoaded(
      searchQuery: _query.isEmpty ? null : _query,
      sortBy: _sortBy,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search products, brands...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) { setState(() => _query = v); _search(); },
          onSubmitted: (_) => _search(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (state is ProductLoaded) {
            if (state.products.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  Text('No products found', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Try a different search term',
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14,
                crossAxisSpacing: 14, childAspectRatio: 0.72,
              ),
              itemCount: state.products.length,
              itemBuilder: (_, i) => ProductCard(product: state.products[i]),
            );
          }
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_rounded, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('Search for products', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ));
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort & Filter', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final sort in [
                ('Newest', null), ('Price ↑', 'price_asc'),
                ('Price ↓', 'price_desc'), ('Top Rated', 'rating'),
              ])
                ChoiceChip(
                  label: Text(sort.$1),
                  selected: _sortBy == sort.$2,
                  selectedColor: AppTheme.primary,
                  onSelected: (_) {
                    setState(() => _sortBy = sort.$2);
                    Navigator.pop(context);
                    _search();
                  },
                ),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() { _sortBy = null; _minPrice = null; _maxPrice = null; });
                Navigator.pop(context);
                _search();
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.surface2,
                foregroundColor: AppTheme.textPrimary,
              ),
              child: const Text('Clear Filters'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
