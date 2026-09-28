"""Print a greeting, so that a job has something to produce.

Kept Python 2 compatible on purpose: the HTCondor page of the REANA
documentation runs its example on the `python:2.7-slim` image, and this
file exists to reproduce that example as literally as possible.
"""

print("Hello from an HTCondor job at CERN!")
