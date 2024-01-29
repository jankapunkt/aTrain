class Config:
    """
    Global Application state
    """
    standalone = False

    def __init__(self):
        self.standalone = False


config = Config()
