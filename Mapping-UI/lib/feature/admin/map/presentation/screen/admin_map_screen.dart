import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/models/market_map_model.dart';
import '../../../../../core/widgets/buyer_loading.dart';
import '../cubit/admin_map_cubit.dart';
import '../cubit/admin_map_state.dart';

class AdminMapScreen extends StatelessWidget {
  const AdminMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminMapCubit()..loadMapData(),
      child: const AdminMapView(),
    );
  }
}

class AdminMapView extends StatelessWidget {
  const AdminMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocBuilder<AdminMapCubit, AdminMapState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const BuyerLoading(message: 'Đang tải sơ đồ...');
            }

            if (state.errorMessage != null) {
              return _buildErrorView(context, state.errorMessage!);
            }

            return Column(
              children: [
                _buildHeader(context, state),
                Expanded(child: _buildGridView(context, state)),
                _buildStoreList(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AdminMapCubit>().loadMapData(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }


  Widget _buildHeader(BuildContext context, AdminMapState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8000), Color(0xFF2F8000)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Sơ đồ Chợ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                if (state.market != null)
                  Text(
                    state.market!.tenCho,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showGridConfigDialog(context, state),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            onPressed: () => context.read<AdminMapCubit>().loadMapData(),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showGridConfigDialog(BuildContext context, AdminMapState state) {
    final grid = state.grid;
    final cellWidthController = TextEditingController(
      text: grid?.cellWidth.toString() ?? '100',
    );
    final cellHeightController = TextEditingController(
      text: grid?.cellHeight.toString() ?? '100',
    );
    final columnsController = TextEditingController(
      text: grid?.columns.toString() ?? '10',
    );
    final rowsController = TextEditingController(
      text: grid?.rows.toString() ?? '10',
    );

    final cubit = context.read<AdminMapCubit>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.grid_on, color: Color(0xFF2F8000)),
            SizedBox(width: 8),
            Text('Cấu hình Sơ đồ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildConfigField(
                      controller: cellWidthController,
                      label: 'Chiều rộng ô',
                      suffix: 'px',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildConfigField(
                      controller: cellHeightController,
                      label: 'Chiều cao ô',
                      suffix: 'px',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildConfigField(
                      controller: columnsController,
                      label: 'Số cột',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildConfigField(
                      controller: rowsController,
                      label: 'Số hàng',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cellWidth = int.tryParse(cellWidthController.text) ?? 100;
              final cellHeight = int.tryParse(cellHeightController.text) ?? 100;
              final columns = int.tryParse(columnsController.text) ?? 10;
              final rows = int.tryParse(rowsController.text) ?? 10;

              Navigator.pop(dialogContext);

              final success = await cubit.updateGridConfig(
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                columns: columns,
                rows: rows,
              );

              if (success) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật cấu hình thành công'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Không thể cập nhật cấu hình'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F8000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, AdminMapState state) {
    final grid = state.grid;
    if (grid == null) {
      return const Center(child: Text('Không có dữ liệu grid'));
    }

    return Column(
      children: [
        // Hiển thị thông tin cấu hình hiện tại
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildConfigChip('${grid.columns}x${grid.rows}', Icons.grid_on),
              const SizedBox(width: 8),
              _buildConfigChip(
                '${grid.cellWidth}x${grid.cellHeight}px',
                Icons.aspect_ratio,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Tính kích thước ô để vừa màn hình (giữ nguyên không đổi theo zoom)
                  final availableWidth = constraints.maxWidth - 32;
                  final availableHeight = constraints.maxHeight - 32;

                  // Tính kích thước ô hiển thị để vừa màn hình
                  final displayCellWidth = availableWidth / grid.columns;
                  final displayCellHeight = availableHeight / grid.rows;
                  // Giữ tỷ lệ ô, lấy kích thước nhỏ hơn
                  final cellSize = displayCellWidth < displayCellHeight
                      ? displayCellWidth
                      : displayCellHeight;

                  final displayGridWidth = cellSize * grid.columns;
                  final displayGridHeight = cellSize * grid.rows;

                  return InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(200),
                    minScale: 0.5,
                    maxScale: 3.0,
                    constrained: false,
                    child: Transform.scale(
                      scale: state.zoomLevel,
                      child: Container(
                        width: displayGridWidth,
                        height: displayGridHeight,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              // Grid background
                              CustomPaint(
                                painter: MarketGridPainter(
                                  rows: grid.rows,
                                  columns: grid.columns,
                                  cellWidth: cellSize,
                                  cellHeight: cellSize,
                                  stores: state.positionedStores,
                                  selectedStoreId: state.selectedStoreId,
                                ),
                                size: Size(displayGridWidth, displayGridHeight),
                              ),
                              // DragTargets for each cell
                              ...List.generate(grid.rows * grid.columns, (index) {
                                final row = index ~/ grid.columns + 1;
                                final col = index % grid.columns + 1;
                                return _buildGridCell(
                                  context,
                                  row,
                                  col,
                                  cellSize,
                                  state,
                                );
                              }),
                              // Positioned stores
                              ...state.positionedStores.map((store) {
                                return _buildStoreMarkerScaled(
                                  context,
                                  store,
                                  state,
                                  cellSize,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Zoom controls
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(
                      context,
                      icon: Icons.add,
                      onTap: () => context.read<AdminMapCubit>().zoomIn(),
                      enabled: state.zoomLevel < 2.0,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '${(state.zoomLevel * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F8000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildZoomButton(
                      context,
                      icon: Icons.remove,
                      onTap: () => context.read<AdminMapCubit>().zoomOut(),
                      enabled: state.zoomLevel > 0.5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoomButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF2F8000) : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[500],
          size: 22,
        ),
      ),
    );
  }

  Widget _buildGridCell(
    BuildContext context,
    int row,
    int col,
    double cellSize,
    AdminMapState state,
  ) {
    final left = (col - 1) * cellSize;
    final top = (row - 1) * cellSize;

    // Check if cell is occupied by another store
    MapStoreInfo? occupyingStore;
    for (final s in state.positionedStores) {
      if (s.gridRow == row && s.gridCol == col) {
        occupyingStore = s;
        break;
      }
    }
    final isOccupied = occupyingStore != null;

    return Positioned(
      left: left,
      top: top,
      child: DragTarget<MapStoreInfo>(
        onWillAcceptWithDetails: (details) {
          final draggedStore = details.data;
          // Allow drop if cell is empty OR if it's the same store (moving back)
          // Don't allow drop on cell occupied by different store
          if (!isOccupied) return true;
          if (occupyingStore!.maGianHang == draggedStore.maGianHang) return true;
          return false;
        },
        onAcceptWithDetails: (details) async {
          final store = details.data;
          // Skip if dropping on same position
          if (store.gridRow == row && store.gridCol == col) return;
          
          final cubit = context.read<AdminMapCubit>();
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          final success = await cubit.updateStorePosition(
            maGianHang: store.maGianHang,
            gridRow: row,
            gridCol: col,
          );

          if (success) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Đã di chuyển "${store.tenGianHang}" đến ô ($row, $col)'),
                backgroundColor: const Color(0xFF4CAF50),
              ),
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final isRejected = rejectedData.isNotEmpty;
          return Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: isRejected
                  ? Colors.red.withValues(alpha: 0.2)
                  : isHovering
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                      : Colors.transparent,
              border: isRejected
                  ? Border.all(color: Colors.red, width: 2)
                  : isHovering
                      ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                      : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoreMarkerScaled(
    BuildContext context,
    MapStoreInfo store,
    AdminMapState state,
    double cellSize,
  ) {
    final isSelected = state.selectedStoreId == store.maGianHang;
    final left = (store.gridCol! - 1) * cellSize;
    final top = (store.gridRow! - 1) * cellSize;

    final storeWidget = Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2F8000)
            : const Color(0xFF4CAF50).withValues(alpha: 0.8),
        border: Border.all(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.white,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            store.tenGianHang,
            style: TextStyle(
              color: Colors.white,
              fontSize: cellSize > 40 ? 10 : 8,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: LongPressDraggable<MapStoreInfo>(
        data: store,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: const Color(0xFF2F8000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                store.tenGianHang,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: cellSize > 40 ? 10 : 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            border: Border.all(color: Colors.grey, width: 1),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            final cubit = context.read<AdminMapCubit>();
            if (isSelected) {
              cubit.clearSelection();
            } else {
              cubit.selectStore(store.maGianHang);
            }
          },
          child: storeWidget,
        ),
      ),
    );
  }

  Widget _buildConfigChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2F8000).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2F8000)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2F8000),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStoreList(BuildContext context, AdminMapState state) {
    final hasSelectedStore = state.selectedStore != null;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách Gian hàng (${state.stores.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (state.unpositionedStores.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.unpositionedStores.length} chưa xếp',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: hasSelectedStore ? 100 : 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: state.stores.length,
              itemBuilder: (context, index) {
                final store = state.stores[index];
                return _buildStoreCard(context, store, state);
              },
            ),
          ),
          if (hasSelectedStore)
            _buildSelectedStoreInfo(context, state.selectedStore!),
        ],
      ),
    );
  }


  Widget _buildStoreCard(
    BuildContext context,
    MapStoreInfo store,
    AdminMapState state,
  ) {
    final isSelected = state.selectedStoreId == store.maGianHang;
    final hasPosition = store.hasPosition;

    final cardContent = Container(
      width: 140,
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2F8000).withValues(alpha: 0.1)
            : hasPosition
                ? const Color(0xFFF8F9FA)
                : Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2F8000)
              : hasPosition
                  ? const Color(0xFFE5E5E5)
                  : Colors.orange.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasPosition ? const Color(0xFF4CAF50) : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  store.tenGianHang,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isSelected
                        ? const Color(0xFF2F8000)
                        : const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!hasPosition)
                const Icon(Icons.drag_indicator, size: 14, color: Colors.orange),
            ],
          ),
          const Spacer(),
          if (store.nguoiDung != null)
            Text(
              store.nguoiDung!.tenNguoiDung,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B6B6B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasPosition
                      ? 'Vị trí: ${store.gridRow}, ${store.gridCol}'
                      : 'Kéo thả vào sơ đồ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: hasPosition ? const Color(0xFF4CAF50) : Colors.orange,
                  ),
                ),
              ),
              if (store.danhGiaTb != null) ...[
                const Icon(Icons.star, size: 10, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  store.danhGiaTb!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    // Wrap with Draggable for unpositioned stores
    if (!hasPosition) {
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: LongPressDraggable<MapStoreInfo>(
          data: store,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                store.tenGianHang,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: cardContent,
          ),
          child: GestureDetector(
            onTap: () {
              final cubit = context.read<AdminMapCubit>();
              if (isSelected) {
                cubit.clearSelection();
              } else {
                cubit.selectStore(store.maGianHang);
              }
            },
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          final cubit = context.read<AdminMapCubit>();
          if (isSelected) {
            cubit.clearSelection();
          } else {
            cubit.selectStore(store.maGianHang);
          }
        },
        child: cardContent,
      ),
    );
  }

  Widget _buildSelectedStoreInfo(BuildContext context, MapStoreInfo store) {
    final cubit = context.read<AdminMapCubit>();
    
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2F8000).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F8000).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (store.hinhAnh != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                store.hinhAnh!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey[200],
                  child: const Icon(Icons.store, color: Colors.grey, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Colors.grey, size: 20),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  store.tenGianHang,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (store.nguoiDung != null)
                  Text(
                    'Chủ: ${store.nguoiDung!.tenNguoiDung}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B6B6B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (store.viTri != null)
                  Text(
                    store.viTri!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B6B6B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => cubit.clearSelection(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Color(0xFF6B6B6B)),
            ),
          ),
        ],
      ),
    );
  }
}


/// Custom painter để vẽ grid sơ đồ chợ
class MarketGridPainter extends CustomPainter {
  final int rows;
  final int columns;
  final double cellWidth;
  final double cellHeight;
  final List<MapStoreInfo> stores;
  final String? selectedStoreId;

  MarketGridPainter({
    required this.rows,
    required this.columns,
    required this.cellWidth,
    required this.cellHeight,
    required this.stores,
    this.selectedStoreId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;

    // Vẽ background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Vẽ các ô grid
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRect(rect, gridPaint);
      }
    }

    // Vẽ số hàng và cột
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Số cột ở trên
    for (int col = 0; col < columns; col++) {
      textPainter.text = TextSpan(
        text: '${col + 1}',
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(col * cellWidth + cellWidth / 2 - textPainter.width / 2, 2),
      );
    }

    // Số hàng bên trái
    for (int row = 0; row < rows; row++) {
      textPainter.text = TextSpan(
        text: '${row + 1}',
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(4, row * cellHeight + cellHeight / 2 - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MarketGridPainter oldDelegate) {
    return oldDelegate.rows != rows ||
        oldDelegate.columns != columns ||
        oldDelegate.stores != stores ||
        oldDelegate.selectedStoreId != selectedStoreId;
  }
}
