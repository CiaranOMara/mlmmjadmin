# encoding: utf-8
import json
import web

from libs import regxes
import settings

# API AUTH token name in http request header
auth_token_name = 'HTTP_' + settings.API_AUTH_TOKEN_HEADER_NAME.replace('-', '_').upper()


def strip_mail_ext_address(mail, delimiters=None):
    """Remove '+extension' in email address.

    >>> strip_mail_ext_address('user+ext@domain.com')
    'user@domain.com'
    """

    if not delimiters:
        delimiters = settings.RECIPIENT_DELIMITERS

    (_orig_user, _domain) = mail.split('@', 1)
    for delimiter in delimiters:
        if delimiter in _orig_user:
            (_user, _ext) = _orig_user.split(delimiter, 1)
            return _user + '@' + _domain

    return mail


def is_email(s):
    try:
        s = str(s).strip()
    except UnicodeEncodeError:
        return False

    # Not contain invalid characters and match regular expression
    if regxes.cmp_email.match(s):
        return True

    return False


def is_domain(s):
    try:
        s = str(s).lower()
    except:
        return False

    if len(set(s) & set(r'~!#$%^&*()+\/ ')) > 0 or ('.' not in s):
        return False

    if regxes.cmp_domain.match(s):
        return True
    else:
        return False


def get_auth_token():
    _token = web.ctx.env.get(auth_token_name)
    return _token


def _render_json(d):
    web.header('Content-Type', 'application/json')
    return json.dumps(d)


def api_render(data):
    """Convert given data to a dict and render it."""
    if isinstance(data, dict):
        d = data
    elif isinstance(data, tuple):
        if data[0] is True:
            if len(data) == 2:
                d = {'_success': True, '_data': data[1]}
            else:
                d = {'_success': True}
        else:
            if len(data) == 2:
                d = {'_success': False, '_msg': data[1]}
            else:
                d = {'_success': False}

    elif isinstance(data, bool):
        d = {'_success': data}
    else:
        d = {'_success': False, '_msg': 'INVALID_DATA'}

    return _render_json(d)
