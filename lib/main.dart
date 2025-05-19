import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/material.dart';
import 'package:mobile_cartography/arc_gis_config.dart';
import 'package:mobile_cartography/image_layer.dart';

void main() {
  ArcGisConfig.setUp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PW Demo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _mapViewController = ArcGISMapView.createController();

  final _mapImageLayers = [
    ImageLayer(
      layerName: 'Ukształtowanie terenu',
      layerUri:
          'https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer',
    ),
    ImageLayer(
      layerName:
          'Potencjalne miejsca o znaczeniu archeologicznym - Fredericksburg (Wirginia)',
      layerUri:
          'https://maps.fredericksburgva.gov/arcgis/rest/services/ArchaeologyModel_FeatureService/MapServer',
    ),
    ImageLayer(
      layerName: 'Krajowy Rejestr Miejsc Historycznych - USA',
      layerUri:
          'https://mapservices.nps.gov/arcgis/rest/services/cultural_resources/nrhp_locations/MapServer',
    ),
  ];

  FeatureLayer? _bufferFeatureLayer;
  int _activeLayerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ArcGISMapView(
            controllerProvider: () => _mapViewController,
            onMapViewReady: _setUpMap,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._mapImageLayers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final layer = entry.value;
                      return _buildLayerButton(
                        name: layer.layerName,
                        onTap: () => _activateImageLayer(index),
                        isActive: _activeLayerIndex == index,
                      );
                    }),
                    _buildLayerButton(
                      name: 'Strefy buforowe NY SHPO',
                      onTap: _activateShpoLayer,
                      isActive: _activeLayerIndex == 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton({
    required String name,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.yellow[800] : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onPressed: onTap,
        child: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? Colors.black : Colors.yellow,
          ),
        ),
      ),
    );
  }

  void _setUpMap() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    _mapViewController.arcGISMap = map;

    await _activateImageLayer(0); // domyślna warstwa
  }

  Future<void> _activateImageLayer(int index) async {
    final map = _mapViewController.arcGISMap;
    if (map == null) return;

    map.operationalLayers.clear();
    final imageUri = Uri.parse(_mapImageLayers[index].layerUri);
    final layer = ArcGISMapImageLayer.withUri(imageUri);
    await layer.load();
    map.operationalLayers.add(layer);

    final extent = layer.fullExtent;
    if (extent != null) {
      final viewpoint = Viewpoint.fromTargetExtent(extent);
      _mapViewController.setViewpoint(viewpoint);
    }

    setState(() {
      _activeLayerIndex = index;
    });
  }

  Future<void> _activateShpoLayer() async {
    final map = _mapViewController.arcGISMap;
    if (map == null) return;
    map.operationalLayers.clear();
    if (_bufferFeatureLayer == null) {
      final uri = Uri.parse(
          'https://services.arcgis.com/1xFZPtKn1wKC6POA/ArcGIS/rest/services/Archaeological_Buffer_Areas/FeatureServer/15');
      final table = ServiceFeatureTable.withUri(uri);
      _bufferFeatureLayer = FeatureLayer.withFeatureTable(table);
      _bufferFeatureLayer?.renderer = _classBreaksRenderer();
      await _bufferFeatureLayer?.load();
    }
    map.operationalLayers.add(_bufferFeatureLayer!);
    await _bufferFeatureLayer?.load();
    final extent = _bufferFeatureLayer?.fullExtent;
    if (extent != null) {
      final viewpoint = Viewpoint.fromTargetExtent(extent);
      _mapViewController.setViewpoint(viewpoint);
    }
    setState(() {
      _activeLayerIndex = 3;
    });
  }

  ClassBreak _createClassBreak({
    required String label,
    required double minKm2,
    required double maxKm2,
    required Color fillColor,
    required Color outlineColor,
    required double outlineWidth,
    required SimpleLineSymbolStyle outlineStyle,
  }) {
    return ClassBreak(
      label: label,
      description: '',
      minValue: minKm2 * 1e6,
      maxValue: maxKm2.isFinite ? maxKm2 * 1e6 : double.infinity,
      symbol: SimpleFillSymbol(
        style: SimpleFillSymbolStyle.solid,
        color: fillColor.withOpacity(0.6),
        outline: SimpleLineSymbol(
          color: outlineColor,
          width: outlineWidth,
          style: outlineStyle,
        ),
      ),
    );
  }

  ClassBreaksRenderer _classBreaksRenderer() => ClassBreaksRenderer(
        fieldName: 'Shape__Area',
        classBreaks: [
          _createClassBreak(
            label: 'Małe (do 1 km²)',
            minKm2: 0,
            maxKm2: 1,
            fillColor: Colors.lightGreen,
            outlineColor: Colors.green,
            outlineWidth: 1,
            outlineStyle: SimpleLineSymbolStyle.solid,
          ),
          _createClassBreak(
            label: 'Średnie (1–5 km²)',
            minKm2: 1.000001,
            maxKm2: 5,
            fillColor: Colors.orange,
            outlineColor: Colors.deepOrange,
            outlineWidth: 1,
            outlineStyle: SimpleLineSymbolStyle.dash,
          ),
          _createClassBreak(
            label: 'Duże (powyżej 5 km²)',
            minKm2: 5.000001,
            maxKm2: double.infinity,
            fillColor: Colors.redAccent,
            outlineColor: Colors.red,
            outlineWidth: 1.5,
            outlineStyle: SimpleLineSymbolStyle.solid,
          ),
        ],
      );
}
