# SearxSearch Tool

## Intent

The `searxSearch` tool is designed to provide a search capability for AI agents, leveraging a self-hosted SearxNG instance. It allows agents to query the internet and retrieve relevant information, enhancing their ability to answer questions, gather data, and perform tasks that require up-to-date knowledge.

## Scope

This tool focuses on:

-   **Searching:** Submitting search queries to a specified SearxNG instance.
-   **Extracting:** Parsing the HTML response from SearxNG to extract relevant information such as URLs, titles, and descriptions of search results.
-   **Returning Results:** Formatting and returning the extracted information in a structured string format.

It does *not* handle:

-   **SearxNG Instance Management:** The tool assumes a SearxNG instance is already set up and running. It does not provide functionality to install, configure, or manage a SearxNG instance.
-   **Advanced Search Parameters:** The tool uses a basic set of search parameters. It does not expose all the advanced search options that SearxNG might offer.


## Use

### Initialization

To use the `searxSearch` tool, you must first initialize it with the base URL of your SearxNG instance. This can be done either by passing the `base_url` argument to the constructor or by setting the `SEARXNG_BASE_URL` environment variable.

```python
from sources.tools.searxSearch import searxSearch

# Option 1: Initialize with base_url argument
search_tool = searxSearch(base_url="http://your_searxng_instance.com")

# Option 2: Initialize with SEARXNG_BASE_URL environment variable
import os
os.environ["SEARXNG_BASE_URL"] = "http://your_searxng_instance.com"
search_tool = searxSearch()
```

If no base URL is provided, the tool will raise a `ValueError`.

### Execution

To execute a search query, call the `execute` method with a list containing the search query string as the first element.

```python
results = search_tool.execute(["your search query"])
print(results)
```

The `execute` method returns a string containing the search results, with each result formatted as:

`Title | URL | Description`

and results separated by newlines.

### Error Handling

The `execute` method returns an error message as a string in the following cases:

-   No search query is provided.
-   The search query is empty.
-   A network error occurs during the search request.

The `execution_failure_check` method can be used to check if the execution failed based on the output string. It returns `True` if the output contains the word "Error", and `False` otherwise.

### Dependencies

The `searxSearch` tool depends on the following Python libraries:

-   `requests`: For making HTTP requests to the SearxNG instance.
-   `beautifulsoup4`: For parsing the HTML response from SearxNG.

These dependencies can be installed using pip:

```bash
pip install requests beautifulsoup4
```

### Environment Variables

-   `SEARXNG_BASE_URL`: The base URL of the SearxNG instance. This variable is optional if the base URL is passed as an argument to the constructor.

### Example

```python
from sources.tools.searxSearch import searxSearch
import os

# Ensure the environment variable is set
os.environ["SEARXNG_BASE_URL"] = "http://searx.lan"

# Initialize the tool
search_tool = searxSearch()

# Execute a search query
results = search_tool.execute(["What is the capital of France?"])

# Print the results
print(results)

# Check for errors
if search_tool.execution_failure_check(results):
    print("Search failed.")
else:
    print("Search completed successfully.")
```
