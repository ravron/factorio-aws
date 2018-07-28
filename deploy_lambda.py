#!python3
import os
import shutil
import subprocess
import tempfile
import zipfile
from io import BytesIO
from pathlib import Path

import boto3
from botocore.exceptions import NoCredentialsError
from decorator import contextmanager

BINARY_NAME = 'lambda_handler'

CURRENT_DIR = Path(__file__).resolve().parent


@contextmanager
def make_temp_dir():
    tmp_dir = tempfile.mkdtemp()
    try:
        yield tmp_dir
    finally:
        shutil.rmtree(tmp_dir)


def main():
    print("Compiling...")
    zip_io = BytesIO()
    with make_temp_dir() as temp_dir:
        compiled_output = Path(temp_dir) / BINARY_NAME
        subprocess.check_call(
            [
                'go',
                'build',
                '-o', str(compiled_output),
                'lambda_handler.go',
            ],
            cwd=str(CURRENT_DIR),
            env=dict(os.environ, GOOS='linux')
        )

        zipf = zipfile.ZipFile(zip_io, mode='w', compression=zipfile.ZIP_DEFLATED)

        # We have to use an explicit ZipInfo and the writestr method, since the normal write method doesn't
        # allow you to control the details we need. In particular we want this to look like a unix-created
        # zip that holds an executable file, even if we're on Windows.
        zip_info = zipfile.ZipInfo(BINARY_NAME)
        # Make sure this has the correct permissions. This is taken from a combination
        # of https://stackoverflow.com/a/434689 and experimentation.
        zip_info.external_attr = (0b1 << 31) | (0o777 << 16)
        # Make it look like this was made on a Unix system. For list of systems, see
        # https://bazaar.launchpad.net/~ubuntu-branches/ubuntu/trusty/unzip/trusty/view/head:/zipinfo.c#L1063
        zip_info.create_system = 3
        # Might as well actually compress this sucker.
        zip_info.compress_type = zipfile.ZIP_DEFLATED

        # Add the bytes into the archive and close it up.
        zipf.writestr(zip_info, compiled_output.read_bytes())
        zipf.close()
    zip_bytes = zip_io.getvalue()

    print("Uploading...")
    lambda_client = boto3.client('lambda', region_name='us-west-1')
    try:
        lambda_client.update_function_code(
            FunctionName='start_factorio',
            ZipFile=zip_bytes,
            Publish=True,
        )
    except NoCredentialsError:
        print("It looks like your credentials aren't setup properly. "
              "See https://boto3.readthedocs.io/en/latest/guide/quickstart.html#configuration to do so. "
              "To find your access key ID and secret, go to "
              "https://console.aws.amazon.com/iam/home#/users/<my_user_name>?section=security_credentials "
              "(replacing <my_user_name> with your actual user name). Note that you may need to create a new key, "
              "since that's the only time you can retrieve the key's secret.")
        return
    print("Done!")


if __name__ == '__main__':
    main()
