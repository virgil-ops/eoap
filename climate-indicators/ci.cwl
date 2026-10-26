cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0

$graph:
- class: Workflow
  id: ci
  label: Climate Indicators Processor
  doc: >
    Calculates climate variables, indices, and anomalies (ERA5-Land 2m temperature
    and precipitation, ISIMIP CMIP6 projections) over a given polygon area and
    time period, to evaluate the impact of extreme climate events.
    This tool acts as a thin wrapper: it forwards the computation request as an
    HTTP call to an external service (see the `url` input) and captures the
    JSON response as output — it does not compute the indicators itself.
  inputs:
    "-b":
      type: string
      default: "9.211473,45.417558,9.237282,45.426616"
      label: Area of Interest
      doc: Bounding box, serialized as a string.
    "-s":
      type: string
      default: "2021-02-04"
      label: Start date
      doc: Initial sensing date of the analysis period (YYYY-MM-DD).
    "-e":
      type: string
      default: "2021-03-24"
      label: End date
      doc: Final sensing date of the analysis period (YYYY-MM-DD).
    "-p":
      type: string
      default: "R20mm"
      label: Indicator
      doc: Climate indicator to compute.
    "-t":
      type: string
      label: Time aggregation
      default: "Q"
      doc: Temporal aggregation of the results.
  outputs:
    result:
      type: File
      outputSource: node_flood/result
  steps:
    node_flood:
      run: '#ci-cl'
      in:
        "-b": "-b"
        "-s": "-s"
        "-e": "-e"
        "-p": "-p"
        "-t": "-t"
      out:
      - result

- class: CommandLineTool
  id: ci-cl
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/climate-indicators-processor:1.0.0
    NetworkAccess:
      networkAccess: true
    ResourceRequirement:
      ramMin: 512
      coresMin: 1
  baseCommand:
  - python
  - /app/climate-indicators-processor.py
  stdout: output.json
  inputs:
    "-b":
      type: string
      inputBinding:
        prefix: ---b
    "-s":
      type: string
      inputBinding:
        prefix: ---s
    "-e":
      type: string
      inputBinding:
        prefix: ---e
    "-p":
      type: string
      inputBinding:
        prefix: ---p
    "-t":
      type: string
      inputBinding:
        prefix: ---t
  outputs:
    result:
      type: stdout