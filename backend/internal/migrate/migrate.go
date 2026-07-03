package migrate

import (
	"context"
	"os"
	"path/filepath"
	"runtime"

	"github.com/jackc/pgx/v5/pgxpool"
)

func Run(ctx context.Context, pool *pgxpool.Pool) error {
	sql, err := os.ReadFile(migrationPath())
	if err != nil {
		return err
	}
	_, err = pool.Exec(ctx, string(sql))
	return err
}

func migrationPath() string {
	_, filename, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(filename), "../../migrations/001_initial.sql")
}
