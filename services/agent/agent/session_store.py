sessions = {}


def get_session(session_id):

    if session_id not in sessions:
        sessions[session_id] = {}

    return sessions[session_id]


def update_session(session_id, key, value):

    session = get_session(session_id)
    session[key] = value


def clear_session(session_id):

    if session_id in sessions:
        del sessions[session_id]