import 'package:flutter/material.dart';

class FeatureIconHelper {
  static IconData getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'air conditioning':
        return Icons.ac_unit;
      case 'power steering':
        return Icons.zoom_out_map;
      case 'power windows':
        return Icons.crop_square;
      case 'abs':
        return Icons.do_not_disturb_on;
      case 'airbags':
        return Icons.airline_seat_recline_normal;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'cruise control':
        return Icons.speed;
      case 'parking sensors':
        return Icons.sensors;
      case 'backup camera':
        return Icons.camera_rear;
      case 'navigation system':
        return Icons.gps_fixed;
      case 'sunroof':
        return Icons.wb_sunny;
      case 'leather seats':
        return Icons.event_seat;
      case 'heated seats':
        return Icons.heat_pump;
      case 'usb port':
        return Icons.usb;
      case 'aux input':
        return Icons.headphones;
      case 'fm radio':
        return Icons.radio;
      case 'alloys':
        return Icons.album;
      case 'spoiler':
        return Icons.arrow_upward;
      case 'rear wiper':
        return Icons.waves;
      case 'power locks':
        return Icons.lock;
      case 'navigation':
        return Icons.map;
      case 'keyless entry':
        return Icons.key;
      case 'dvd':
        return Icons.movie;
      default:
        return Icons.check_circle;
    }
  }
}
