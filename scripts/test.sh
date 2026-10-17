
#!/usr/bin/env bash
set -u

KERNEL="build/kernel.elf"
LOG="/tmp/kernel_test_output.txt"
TIMEOUT=10

# Colors
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN='' RED='' CYAN='' YELLOW='' BOLD='' RESET=''
fi

if [ ! -f "$KERNEL" ]; then
    echo -e "${RED}ERROR${RESET}: $KERNEL not found. Run 'make' first."
    exit 1
fi

printf "\n${BOLD}AArch64 Kernel Test Suite${RESET}\n"
printf '%s\n\n' "----------------------------------------"

: > "$LOG"

qemu-system-aarch64 \
    -M virt -cpu cortex-a57 -m 128M -nographic \
    -kernel "$KERNEL" > "$LOG" 2>&1 &
pid=$!

cleanup() {
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

line_no=1
deadline=$((SECONDS + TIMEOUT))
timed_out=1

while [ "$SECONDS" -lt "$deadline" ]; do
    current_line=$(wc -l < "$LOG")
    if [ "$current_line" -ge "$line_no" ]; then
        sed -n "${line_no},${current_line}p" "$LOG" |
        while IFS= read -r line; do
            case "$line" in
                PASS:*)
                    printf "${GREEN}✓ PASS${RESET} %s\n" "${line#PASS: }"
                    ;;
                FAIL:*)
                    printf "${RED}✗ FAIL${RESET} %s\n" "${line#FAIL: }"
                    ;;
                "ALL TESTS PASSED")
                    printf "\n${GREEN}${BOLD}✓ ALL TESTS PASSED${RESET}\n"
                    ;;
                "Tick: "*)
                    printf "${CYAN}⏱ %s${RESET}\n" "$line"
                    ;;
                "Hello, AArch64!"|"---------- Begin tests ----------"|"---------- End tests ----------")
                    printf "${YELLOW}%s${RESET}\n" "$line"
                    ;;
                *)
                    [ -n "$line" ] && printf '%s\n' "$line"
                    ;;
            esac
        done

        line_no=$((current_line + 1))
    fi

    if grep -q '^FAIL:' "$LOG"; then
        timed_out=0
        break
    fi

    if grep -q 'ALL TESTS PASSED' "$LOG" &&
       grep -q 'Tick: ' "$LOG"; then
        timed_out=0
        break
    fi

    if ! kill -0 "$pid" 2>/dev/null; then
        break
    fi

    sleep 0.1
done

cleanup
trap - EXIT INT TERM

current_line=$(wc -l < "$LOG")
if [ "$current_line" -ge "$line_no" ]; then
    sed -n "${line_no},${current_line}p" "$LOG" |
    while IFS= read -r line; do
        case "$line" in
            PASS:*) printf "${GREEN}✓ PASS${RESET} %s\n" "${line#PASS: }" ;;
            FAIL:*) printf "${RED}✗ FAIL${RESET} %s\n" "${line#FAIL: }" ;;
            "Tick: "*) printf "${CYAN}⏱ %s${RESET}\n" "$line" ;;
            *) [ -n "$line" ] && printf '%s\n' "$line" ;;
        esac
    done
fi


passed=$(sed '/^ALL TESTS PASSED/,$d' "$LOG" | grep -c '^PASS:' || true)
failed=$(sed '/^ALL TESTS PASSED/,$d' "$LOG" | grep -c '^FAIL:' || true)
tick_found=0
all_passed=0

grep -q 'ALL TESTS PASSED' "$LOG" && all_passed=1
grep -q 'Tick: ' "$LOG" && tick_found=1

printf '\n%s\n' "----------------------------------------"
printf "Tests       : "

if [ "$failed" -eq 0 ] && [ "$all_passed" -eq 1 ]; then
    printf "\033[0;32m%d passed\033[0m" "$passed"
else
    printf "\033[0;32m%d passed\033[0m" "$passed"
fi

printf ", "

if [ "$failed" -eq 0 ]; then
    printf "\033[0;31m%d failed\033[0m\n" "$failed"
else
    printf "\033[0;31m%d failed\033[0m\n" "$failed"
fi

printf "Timer / IRQ : "
if [ "$tick_found" -eq 1 ]; then
    printf "\033[0;32mPASS\033[0m\n"
else
    printf "\033[0;31mFAIL\033[0m\n"
fi

printf '%s\n' "----------------------------------------"

if [ "$all_passed" -eq 1 ] &&
   [ "$tick_found" -eq 1 ] &&
   [ "$failed" -eq 0 ] &&
   [ "$timed_out" -eq 0 ]; then
    printf "\033[0;32m✓ PASS: kernel test suite\033[0m\n"
    exit 0
fi

printf "\033[0;31m✗ FAIL: kernel test suite\033[0m\n"
exit 1
