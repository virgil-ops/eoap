cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.0

$graph:
- class: Workflow
  id: flood-risk-fixed-value
  label: Flood Risk Fixed Value
  doc: Flood exposure metrics for a polygon under an SSP scenario, storm surge return period and year.
  inputs:
    confidence:
      type: string
      default: medium
      label: Confidence
      doc: Confidence level of the flood model.
    bbox:
      type: string
      default: "0.6,0.7,0.7,40.8"
      label: Area of Interest
      doc: GeoJSON Polygon bbox, serialized as a JSON string.
    ssp:
      type: string
      default: "ssp245"
      label: SSP Scenario
      doc: Shared Socioeconomic Pathway.
    storm_surge:
      type: string
      default: "1_0"
      label: Storm Surge Return Period
      doc: Return period identifier.
    year:
      type: string
      label: Year
      default: "2100"
      doc: Target year for the flood projection.
  outputs:
    result:
      type: File
      outputSource: node_flood/result
  steps:
    node_flood:
      run: '#flood-risk-cl'
      in:
        confidence: confidence
        bbox: bbox
        ssp: ssp
        storm_surge: storm_surge
        year: year
      out:
      - result

- class: CommandLineTool
  id: flood-risk-cl
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/flood-risk-fixed-value-processor:1.0.0
    NetworkAccess:
      networkAccess: true
    ResourceRequirement:
      ramMin: 512
      coresMin: 1
  baseCommand:
  - python
  - /app/flood-risk-fixed-value-processor.py
  stdout: output.json
  inputs:
    confidence:
      type: string
      inputBinding:
        prefix: --confidence
    bbox:
      type: string
      inputBinding:
        prefix: --bbox
    ssp:
      type: string
      inputBinding:
        prefix: --ssp
    storm_surge:
      type: string
      inputBinding:
        prefix: --storm_surge
    year:
      type: string
      inputBinding:
        prefix: --year
  outputs:
    result:
      type: stdout