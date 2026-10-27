"""
Compile desplit.proto into Python gRPC stubs.
"""
import sys
from pathlib import Path
from grpc_tools import protoc

proto_dir = Path(__file__).parent.resolve()
proto_file = proto_dir / "desplit.proto"

if not proto_file.exists():
    print(f"Error: {proto_file} not found")
    sys.exit(1)

args = [
    "protoc",
    f"-I{proto_dir}",
    f"--python_out={proto_dir}",
    f"--grpc_python_out={proto_dir}",
    str(proto_file),
]

print(f"Compiling {proto_file.name}...")
code = protoc.main(args)
if code == 0:
    print("Compilation successful! Generated desplit_pb2.py and desplit_pb2_grpc.py")
else:
    print(f"Compilation failed with exit code {code}")
    sys.exit(code)
