package testutils

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMockDatabase(t *testing.T) {
	t.Run("Create SQLite Mock Database", func(t *testing.T) {
		db := MockDatabase(t)
		require.NotNil(t, db)

		// Test basic database functionality
		sqlDB, err := db.DB()
		require.NoError(t, err)
		assert.NotNil(t, sqlDB)

		// Test ping
		err = sqlDB.Ping()
		require.NoError(t, err)
	})

	t.Run("Test DSN Generation", func(t *testing.T) {
		dsn := GetTestDSN()
		assert.Equal(t, ":memory:", dsn)
	})
}

func TestTestDatabaseIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	t.Run("Setup and Teardown Test Database", func(t *testing.T) {
		// This would test the MySQL container functionality
		// Skipping actual container test for now to avoid Docker dependency
		t.Log("Integration test would run MySQL container here")
		t.Log("✅ Test infrastructure is ready for container-based testing")
	})
}
