/// QR 코드 데이터 파싱 서비스
/// QR에는 "rasplab://MAC주소" 형식으로 인코딩됨
class QrService {
  static const String _scheme = 'rasplab://';

  /// QR 스캔 결과 문자열에서 MAC 주소 추출
  /// 실패 시 null 반환
  static String? parseMacAddress(String qrData) {
    if (!qrData.startsWith(_scheme)) return null;
    final mac = qrData.substring(_scheme.length).trim().toUpperCase();
    final macRegex = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');
    return macRegex.hasMatch(mac) ? mac : null;
  }

  /// MAC 주소를 QR 데이터 형식으로 인코딩
  static String encodeMacAddress(String mac) => '$_scheme$mac';
}
