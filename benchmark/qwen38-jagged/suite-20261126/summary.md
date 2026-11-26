# Article suite summary

- bench IQ4_XS: decode 117.5 prefill 1723
- bench Q4_K_XL: decode 96.7 prefill 1291
- decode delta IQ4_XS vs Q4_K_XL: +21.5%
- probe probe-A-iq4xs.json: refusal 8/8, empty 0, strict 5/5, edit 5/5
- probe probe-B-q4kxl.json: refusal 7/8, empty 0, strict 5/5, edit 5/5
- ladder ladder-A-iq4xs.json: {"ok": 18, "TRUNCATED": 9, "no-call": 0, "no-field": 0, "wrong-string": 13}
- ladder ladder-B-q4kxl.json: {"ok": 19, "TRUNCATED": 17, "no-call": 0, "no-field": 0, "wrong-string": 4}
- nondet nondet-A-iq4xs.json: 1/5 distinct
- nondet nondet-B-q4kxl.json: 1/5 distinct
- toolcall.json: {"ok": true, "call": {"name": "get_weather", "arguments": "{\"city\":\"Oslo\",\"unit\":\"c\"}"}}
- needle.json: {"prompt_tokens": 130085, "hit": true}
