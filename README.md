# llhttp
[![CI](https://github.com/nodejs/llhttp/workflows/CI/badge.svg)](https://github.com/nodejs/llhttp/actions?query=workflow%3ACI)

Port of [http_parser][0] to [llparse][1].

## Why?

Let's face it, [http_parser][0] is practically unmaintainable. Even
introduction of a single new method results in a significant code churn.

This project aims to:

* Make it maintainable
* Verifiable
* Improving benchmarks where possible

More details in [Fedor Indutny's talk at JSConf EU 2019](https://youtu.be/x3k_5Mi66sY)

## How?

Over time, different approaches for improving [http_parser][0]'s code base
were tried. However, all of them failed due to resulting significant performance
degradation.

This project is a port of [http_parser][0] to TypeScript. [llparse][1] is used
to generate the output C source file, which could be compiled and
linked with the embedder's program (like [Node.js][7]).

## Performance

So far llhttp outperforms http_parser:

|                 | input size |  bandwidth   |  reqs/sec  |   time  |
|:----------------|-----------:|-------------:|-----------:|--------:|
| **llhttp**      | 8192.00 mb | 1777.24 mb/s | 3583799.39 req/sec | 4.61 s |
| **http_parser** | 8192.00 mb | 694.66 mb/s | 1406180.33 req/sec | 11.79 s |

llhttp is faster by approximately **156%**.

## Maintenance

llhttp project has about 1400 lines of TypeScript code describing the parser
itself and around 450 lines of C code and headers providing the helper methods.
The whole [http_parser][0] is implemented in approximately 2500 lines of C, and
436 lines of headers.

All optimizations and multi-character matching in llhttp are generated
automatically, and thus doesn't add any extra maintenance cost. On the contrary,
most of http_parser's code is hand-optimized and unrolled. Instead describing
"how" it should parse the HTTP requests/responses, a maintainer should
implement the new features in [http_parser][0] cautiously, considering
possible performance degradation and manually optimizing the new code.

## Verification

The state machine graph is encoded explicitly in llhttp. The [llparse][1]
automatically checks the graph for absence of loops and correct reporting of the
input ranges (spans) like header names and values. In the future, additional
checks could be performed to get even stricter verification of the llhttp.

## Usage

```C
#include "llhttp.h"

llhttp_t parser;
llhttp_settings_t settings;

/* Initialize user callbacks and settings */
llhttp_settings_init(&settings);

/* Set user callback */
settings.on_message_complete = handle_on_message_complete;

/* Initialize the parser in HTTP_BOTH mode, meaning that it will select between
 * HTTP_REQUEST and HTTP_RESPONSE parsing automatically while reading the first
 * input.
 */
llhttp_init(&parser, HTTP_BOTH, &settings);

/* Parse request! */
const char* request = "GET / HTTP/1.1\r\n\r\n";
int request_len = strlen(request);

enum llhttp_errno err = llhttp_execute(&parser, request, request_len);
if (err == HPE_OK) {
  /* Successfully parsed! */
} else {
  fprintf(stderr, "Parse error: %s %s\n", llhttp_errno_name(err),
          parser.reason);
}
```
For more information on API usage, please refer to [src/native/api.h](https://github.com/nodejs/llhttp/blob/main/src/native/api.h).

## Build Instructions

Make sure you have [Node.js](https://nodejs.org/), npm and npx installed. Then under project directory run:

```sh
npm install
make
```

---

### Bindings to other languages

* Lua: [MunifTanjim/llhttp.lua][11]
* Python: [pallas/pyllhttp][8]
* Ruby: [metabahn/llhttp][9]
* Rust: [JackLiar/rust-llhttp][10]

### Using with CMake

If you want to use this library in a CMake project you can use the snippet below.

```
FetchContent_Declare(llhttp
  URL "https://github.com/nodejs/llhttp/archive/refs/tags/v6.0.5.tar.gz")  # Using version 6.0.5

FetchContent_MakeAvailable(llhttp)

target_link_libraries(${EXAMPLE_PROJECT_NAME} ${PROJECT_LIBRARIES} llhttp ${PROJECT_NAME})
```

## Building on Windows

### Installation

* `choco install git`
* `choco install node`
* `choco install llvm` (or install the `C++ Clang tools for Windows` optional package from the Visual Studio 2019 installer)
* `choco install make` (or if you have MinGW, it comes bundled)

1. Ensure that `Clang` and `make` are in your system path.
2. Using Git Bash, clone the repo to your preferred location.
3. Cd into the cloned directory and run `npm install`
5. Run `make`
6. Your `repo/build` directory should now have `libllhttp.a` and `libllhttp.so` static and dynamic libraries.
7. When building your executable, you can link to these libraries. Make sure to set the build folder as an include path when building so you can reference the declarations in `repo/build/llhttp.h`.

### A simple example on linking with the library:

Assuming you have an executable `main.cpp` in your current working directory, you would run: `clang++ -Os -g3 -Wall -Wextra -Wno-unused-parameter -I/path/to/llhttp/build main.cpp /path/to/llhttp/build/libllhttp.a -o main.exe`.

If you are getting `unresolved external symbol` linker errors you are likely attempting to build `llhttp.c` without linking it with object files from `api.c` and `http.c`.

#### LICENSE

This software is licensed under the MIT License.

Copyright Fedor Indutny, 2018.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.

[0]: https://github.com/nodejs/http-parser
[1]: https://github.com/nodejs/llparse
[2]: https://en.wikipedia.org/wiki/Register_allocation#Spilling
[3]: https://en.wikipedia.org/wiki/Tail_call
[4]: https://llvm.org/docs/LangRef.html
[5]: https://llvm.org/docs/LangRef.html#call-instruction
[6]: https://clang.llvm.org/
[7]: https://github.com/nodejs/node
[8]: https://github.com/pallas/pyllhttp
[9]: https://github.com/metabahn/llhttp
[10]: https://github.com/JackLiar/rust-llhttp
[11]: https://github.com/MunifTanjim/llhttp.lua
