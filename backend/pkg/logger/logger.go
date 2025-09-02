package logger

import (
	"context"
	"os"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Logger *zap.Logger

// RequestID context key
type ctxKey string

const RequestIDKey ctxKey = "request_id"

// InitLogger initializes the global logger
func InitLogger(environment string) error {
	var config zap.Config

	if environment == "production" {
		// Production config with JSON format
		config = zap.Config{
			Level:       zap.NewAtomicLevelAt(zap.InfoLevel),
			Development: false,
			Sampling: &zap.SamplingConfig{
				Initial:    100,
				Thereafter: 100,
			},
			Encoding: "json",
			EncoderConfig: zapcore.EncoderConfig{
				TimeKey:        "timestamp",
				LevelKey:       "level",
				NameKey:        "logger",
				CallerKey:      "caller",
				FunctionKey:    zapcore.OmitKey,
				MessageKey:     "message",
				StacktraceKey:  "stacktrace",
				LineEnding:     zapcore.DefaultLineEnding,
				EncodeLevel:    zapcore.LowercaseLevelEncoder,
				EncodeTime:     zapcore.ISO8601TimeEncoder,
				EncodeDuration: zapcore.SecondsDurationEncoder,
				EncodeCaller:   zapcore.ShortCallerEncoder,
			},
			OutputPaths:      []string{"stdout"},
			ErrorOutputPaths: []string{"stderr"},
		}
	} else {
		// Development config with console format
		config = zap.Config{
			Level:       zap.NewAtomicLevelAt(zap.DebugLevel),
			Development: true,
			Encoding:    "console",
			EncoderConfig: zapcore.EncoderConfig{
				TimeKey:        "T",
				LevelKey:       "L",
				NameKey:        "N",
				CallerKey:      "C",
				FunctionKey:    zapcore.OmitKey,
				MessageKey:     "M",
				StacktraceKey:  "S",
				LineEnding:     zapcore.DefaultLineEnding,
				EncodeLevel:    zapcore.CapitalColorLevelEncoder,
				EncodeTime:     zapcore.ISO8601TimeEncoder,
				EncodeDuration: zapcore.StringDurationEncoder,
				EncodeCaller:   zapcore.ShortCallerEncoder,
			},
			OutputPaths:      []string{"stdout"},
			ErrorOutputPaths: []string{"stderr"},
		}
	}

	var err error
	Logger, err = config.Build()
	if err != nil {
		return err
	}

	// Add hostname to logger context
	hostname, _ := os.Hostname()
	Logger = Logger.With(
		zap.String("service", "blogcms-api"),
		zap.String("hostname", hostname),
	)

	return nil
}

// GetLogger returns the global logger
func GetLogger() *zap.Logger {
	if Logger == nil {
		// Fallback logger if not initialized
		Logger, _ = zap.NewProduction()
	}
	return Logger
}

// GetLoggerWithRequestID returns logger with request ID from context
func GetLoggerWithRequestID(ctx context.Context) *zap.Logger {
	logger := GetLogger()

	if requestID, ok := ctx.Value(RequestIDKey).(string); ok && requestID != "" {
		return logger.With(zap.String("request_id", requestID))
	}

	return logger
}

// LogHTTPRequest logs HTTP request details
func LogHTTPRequest(ctx context.Context, method, path string, statusCode int, duration time.Duration, clientIP, userAgent string) {
	logger := GetLoggerWithRequestID(ctx)

	fields := []zap.Field{
		zap.String("method", method),
		zap.String("path", path),
		zap.Int("status_code", statusCode),
		zap.Duration("duration", duration),
		zap.String("client_ip", clientIP),
		zap.String("user_agent", userAgent),
	}

	level := getLogLevelByStatusCode(statusCode)
	switch level {
	case zapcore.ErrorLevel:
		logger.Error("HTTP request", fields...)
	case zapcore.WarnLevel:
		logger.Warn("HTTP request", fields...)
	default:
		logger.Info("HTTP request", fields...)
	}
}

// LogError logs error with context
func LogError(ctx context.Context, message string, err error, fields ...zap.Field) {
	logger := GetLoggerWithRequestID(ctx)

	allFields := append(fields, zap.Error(err))
	logger.Error(message, allFields...)
}

// LogInfo logs info message with context
func LogInfo(ctx context.Context, message string, fields ...zap.Field) {
	logger := GetLoggerWithRequestID(ctx)
	logger.Info(message, fields...)
}

// LogWarn logs warning message with context
func LogWarn(ctx context.Context, message string, fields ...zap.Field) {
	logger := GetLoggerWithRequestID(ctx)
	logger.Warn(message, fields...)
}

// LogDebug logs debug message with context
func LogDebug(ctx context.Context, message string, fields ...zap.Field) {
	logger := GetLoggerWithRequestID(ctx)
	logger.Debug(message, fields...)
}

// getLogLevelByStatusCode determines log level based on HTTP status code
func getLogLevelByStatusCode(statusCode int) zapcore.Level {
	switch {
	case statusCode >= 500:
		return zapcore.ErrorLevel
	case statusCode >= 400:
		return zapcore.WarnLevel
	default:
		return zapcore.InfoLevel
	}
}

// Sync flushes any buffered log entries
func Sync() {
	if Logger != nil {
		Logger.Sync()
	}
}
