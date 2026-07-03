.PHONY: test migrate run smoke tidy

test:
	cd backend && GO_ENV=test go test ./... -count=1

migrate:
	cd backend && go run ./cmd/server migrate

run:
	cd backend && go run ./cmd/server

smoke:
	./backend/scripts/smoke.sh

tidy:
	cd backend && go mod tidy
