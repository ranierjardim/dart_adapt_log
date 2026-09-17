# Roda o comando em todos os pacotes de src/. Pacotes com `sdk: flutter`
# usam a CLI do Flutter; os demais, a do Dart.
PACKAGES := $(sort $(dir $(wildcard src/*/pubspec.yaml)))

define run_in_packages
	@for d in $(PACKAGES); do \
	  echo "==> $$d"; \
	  if grep -q "sdk: flutter" $$d/pubspec.yaml; then \
	    (cd $$d && flutter $(1)) || exit 1; \
	  else \
	    (cd $$d && dart $(1)) || exit 1; \
	  fi; \
	done
endef

.PHONY: pubget analyze test check

pubget:
	$(call run_in_packages,pub get)

analyze:
	$(call run_in_packages,analyze)

test:
	$(call run_in_packages,test)

check: analyze test
