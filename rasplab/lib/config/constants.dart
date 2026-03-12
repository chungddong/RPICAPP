// BLE UUID 상수
const String kBleServiceUUID = '0000fff0-0000-1000-8000-00805f9b34fb';
const String kCodeWriteUUID   = '0000fff1-0000-1000-8000-00805f9b34fb';
const String kResultReadUUID  = '0000fff2-0000-1000-8000-00805f9b34fb';
const String kControlUUID     = '0000fff3-0000-1000-8000-00805f9b34fb';
const String kStatusUUID      = '0000fff4-0000-1000-8000-00805f9b34fb';

// BLE 기기 이름 접두사
const String kDeviceNamePrefix = 'RaspLab-';

// BLE 패킷 타입
const int kPacketTypeCodeChunk    = 0x01;
const int kPacketTypeCodeEnd      = 0x02;
const int kPacketTypeStop         = 0x03;
const int kPacketTypeResultChunk  = 0x04;
const int kPacketTypeResultEnd    = 0x05;
const int kPacketTypeError        = 0x06;

// BLE 패킷 최대 페이로드 크기 (헤더 5바이트 제외)
const int kBlePayloadSize = 507;

// 코드 실행 타임아웃 (초)
const int kExecutionTimeoutSeconds = 30;

// Claude API
const String kClaudeApiUrl     = 'https://api.anthropic.com/v1/messages';
const String kClaudeModel      = 'claude-haiku-4-5-20251001';
const int    kClaudeMaxTokens  = 4096;
