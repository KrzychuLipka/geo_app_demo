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
                  children: _mapImageLayers.map((layer) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onPressed: () => _changeActiveImageLayer(
                          layerUri: layer.layerUri,
                        ),
                        child: Text(
                          layer.layerName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setUpMap() async {
    final map = ArcGISMap.withBasemapStyle(BasemapStyle.arcGISTopographic);
    ;
    final ortoPhotoMapImageUri = Uri.parse(_mapImageLayers.first.layerUri);
    final ortoPhotoMapImageLayer =
        ArcGISMapImageLayer.withUri(ortoPhotoMapImageUri);
    await ortoPhotoMapImageLayer.load();
    map.operationalLayers.add(ortoPhotoMapImageLayer);
    _mapViewController.arcGISMap = map;
    final targetExtent = ortoPhotoMapImageLayer.fullExtent;
    if (targetExtent != null) {
      final viewPoint = Viewpoint.fromTargetExtent(targetExtent);
      _mapViewController.setViewpoint(viewPoint);
    }
  }

  Future<void> _changeActiveImageLayer({
    required String layerUri,
  }) async {
    _mapViewController.arcGISMap?.operationalLayers.clear();
    final imageUri = Uri.parse(layerUri);
    final layer = ArcGISMapImageLayer.withUri(imageUri);
    await layer.load();
    _mapViewController.arcGISMap?.operationalLayers.add(layer);
    final targetExtent = layer.fullExtent;
    if (targetExtent != null) {
      final viewPoint = Viewpoint.fromTargetExtent(targetExtent);
      _mapViewController.setViewpoint(viewPoint);
    }
  }
}
