# encoding: utf-8
from . import get, put, debug
from .utils import create_ml, remove_ml
from . import data


def test_invalid_domain():
    url = data.url_ml_in_not_exist_domain
    _json = get(url=url)
    assert _json['_success'] is False
    assert _json['_msg'] == 'NO_SUCH_ACCOUNT'


def test_invalid_ml():
    # Make sure account doesn't exist
    remove_ml()

    url = data.url_ml

    _json = get(url=url)
    assert _json['_success'] is False
    assert _json['_msg'] == 'NO_SUCH_ACCOUNT'


def test_create_ml():
    create_ml(_remove_ml=True)


def test_update_ml():
    create_ml(_remove_ml=False)

    url = data.url_ml

    _json = get(url=url)
    assert _json['_success'] is True

    params = data.params_update_ml

    _json = put(url=url, data=params)
    assert _json['_success'] is True

    _json = get(url=url)
    assert _json['_success'] is True

    _data = _json['_data']
    for k in params:
        if params[k] != _data[k]:
            debug(_data)
            debug(k, params[k], _data[k])

        assert params[k] == _data[k]


def test_archive_ml():
    # TODO How to get path of archived ml directory?
    # TODO How to verify path exists?
    pass
