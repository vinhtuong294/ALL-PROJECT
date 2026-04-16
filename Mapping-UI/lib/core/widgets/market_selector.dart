import 'package:flutter/material.dart';
import '../models/khu_vuc_model.dart';
import '../models/cho_model.dart';
import '../services/khu_vuc_service.dart';
import '../services/cho_service.dart';
import '../dependency/injection.dart';

/// Widget chọn khu vực và chợ - dùng chung cho nhiều màn hình
class MarketSelector extends StatelessWidget {
  final String? selectedRegion;
  final String? selectedRegionMa;
  final String? selectedMarket;
  final String? selectedMarketMa;
  final Function(String maKhuVuc, String tenKhuVuc) onRegionSelected;
  final Function(String maCho, String tenCho) onMarketSelected;

  const MarketSelector({
    super.key,
    this.selectedRegion,
    this.selectedRegionMa,
    this.selectedMarket,
    this.selectedMarketMa,
    required this.onRegionSelected,
    required this.onMarketSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRegionDialog(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF2F8000).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF2F8000),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn khu vực',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedRegion ?? 'Chưa chọn khu vực',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selectedRegion != null
                              ? const Color(0xFF1C1C1E)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
                // Phần chọn chợ - chỉ hiện khi đã chọn khu vực
                if (selectedRegion != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showMarketDialog(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn chợ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedMarket ?? 'Tất cả các chợ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Color(0xFF8E8E93),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog chọn khu vực
  void _showRegionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _RegionDialog(
          onRegionSelected: (maKhuVuc, tenKhuVuc) {
            onRegionSelected(maKhuVuc, tenKhuVuc);
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  /// Hiển thị dialog chọn chợ
  void _showMarketDialog(BuildContext context) {
    if (selectedRegionMa == null) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _MarketDialog(
          maKhuVuc: selectedRegionMa!,
          onMarketSelected: (maCho, tenCho) {
            onMarketSelected(maCho, tenCho);
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}

/// Dialog chọn khu vực
class _RegionDialog extends StatefulWidget {
  final Function(String maKhuVuc, String tenKhuVuc) onRegionSelected;

  const _RegionDialog({required this.onRegionSelected});

  @override
  State<_RegionDialog> createState() => _RegionDialogState();
}

class _RegionDialogState extends State<_RegionDialog> {
  final KhuVucService _khuVucService = getIt<KhuVucService>();
  List<KhuVucModel>? _khuVucList;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchKhuVucList();
  }

  Future<void> _fetchKhuVucList() async {
    try {
      final khuVucList = await _khuVucService.getKhuVucList(
        page: 1,
        limit: 12,
        sort: 'phuong',
        order: 'asc',
      );
      setState(() {
        _khuVucList = khuVucList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách khu vực';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn khu vực'),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_khuVucList == null || _khuVucList!.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Không có khu vực nào')),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _khuVucList!.length,
        itemBuilder: (context, index) {
          final khuVuc = _khuVucList![index];
          return ListTile(
            title: Text(khuVuc.phuong),
            subtitle: Text('Số chợ: ${khuVuc.soCho}'),
            onTap: () => widget.onRegionSelected(
              khuVuc.maKhuVuc,
              khuVuc.phuong,
            ),
          );
        },
      ),
    );
  }
}

/// Dialog chọn chợ
class _MarketDialog extends StatefulWidget {
  final String maKhuVuc;
  final Function(String maCho, String tenCho) onMarketSelected;

  const _MarketDialog({
    required this.maKhuVuc,
    required this.onMarketSelected,
  });

  @override
  State<_MarketDialog> createState() => _MarketDialogState();
}

class _MarketDialogState extends State<_MarketDialog> {
  final ChoService _choService = getIt<ChoService>();
  List<ChoModel>? _choList;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchChoList();
  }

  Future<void> _fetchChoList() async {
    try {
      final choList = await _choService.getChoListByKhuVuc(
        maKhuVuc: widget.maKhuVuc,
        page: 1,
        limit: 12,
        sort: 'ten_cho',
        order: 'asc',
      );
      setState(() {
        _choList = choList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải danh sách chợ';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn chợ'),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_choList == null || _choList!.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Không có chợ nào trong khu vực này')),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _choList!.length,
        itemBuilder: (context, index) {
          final cho = _choList![index];
          return ListTile(
            title: Text(cho.tenCho),
            subtitle: Text('Số gian hàng: ${cho.soGianHang}'),
            onTap: () => widget.onMarketSelected(
              cho.maCho,
              cho.tenCho,
            ),
          );
        },
      ),
    );
  }
}
