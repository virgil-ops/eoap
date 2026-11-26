cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 0.1.7

$graph:
- class: Workflow
  id: ai-road-extraction
  label: AI Road Extraction
  doc: >
    Stages basemap or Sentinel-2 L2A imagery, generates georeferenced binary
    road masks, and builds a STAC Catalog with the shared DPH stage-out tool.
  inputs:
    bbox:
      type: string
      label: Area of interest
      doc: Bounding box in west,south,east,north order (EPSG:4326), at most 100 km2.
    source:
      type:
        type: enum
        symbols: [BaseLayer, Sentinel2L2AImagery]
      default: BaseLayer
      label: Image source
      doc: Use the basemap or Sentinel-2 L2A imagery.
    sensitivity:
      type: float
      default: 0.1
      label: Sensitivity
      doc: Road-probability threshold between 0 and 1.
    start_date:
      type: ["null", string]
      default: null
      label: Start date
      doc: Required for Sentinel-2, in YYYY-MM-DD format.
    end_date:
      type: ["null", string]
      default: null
      label: End date
      doc: Required for Sentinel-2, in YYYY-MM-DD format.
  outputs:
    catalog_uri:
      type: Directory
      label: Road extraction results
      doc: STAC Catalog with road mask GeoTIFFs and processing metadata.
      outputSource: stage_out/catalog_dir
  steps:
    stage_in:
      run: "#stage-in"
      in:
        bbox: bbox
        source: source
        start_date: start_date
        end_date: end_date
      out: [staged_dir]
    process:
      run: "#process"
      in:
        source_dir: stage_in/staged_dir
        sensitivity: sensitivity
      out: [results_dir]
    stage_out:
      run: "#stage-out"
      in:
        input_dir: process/results_dir
      out: [catalog_dir]

- class: CommandLineTool
  id: stage-in
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/road-seg-stage-in:1.0.0
    NetworkAccess:
      networkAccess: true
    ResourceRequirement:
      coresMin: 1
      ramMin: 2048
  baseCommand: [python, /app/stage_in.py]
  inputs:
    bbox:
      type: string
      inputBinding:
        prefix: --bbox=
        separate: false
    source:
      type:
        type: enum
        symbols: [BaseLayer, Sentinel2L2AImagery]
      default: BaseLayer
      inputBinding:
        prefix: --source
    start_date:
      type: ["null", string]
      default: null
      inputBinding:
        prefix: --start-date
    end_date:
      type: ["null", string]
      default: null
      inputBinding:
        prefix: --end-date
    outdir:
      type: string
      default: staged
      inputBinding:
        prefix: --outdir
  outputs:
    staged_dir:
      type: Directory
      outputBinding:
        glob: staged

- class: CommandLineTool
  id: process
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/road-seg-process:1.0.0
    NetworkAccess:
      networkAccess: true
    ResourceRequirement:
      coresMin: 1
      ramMin: 2048
  baseCommand: [python, /app/process.py]
  inputs:
    source_dir:
      type: Directory
      inputBinding:
        prefix: --source-dir
    sensitivity:
      type: float
      default: 0.1
      inputBinding:
        prefix: --sensitivity
    outdir:
      type: string
      default: results
      inputBinding:
        prefix: --outdir
  outputs:
    results_dir:
      type: Directory
      outputBinding:
        glob: results

- class: CommandLineTool
  id: stage-out
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/dph-stac-stage-out:1.0.0
    NetworkAccess:
      networkAccess: false
    ResourceRequirement:
      coresMin: 1
      ramMin: 256
  baseCommand: [python, /app/stage_out.py]
  inputs:
    input_dir:
      type: Directory
      inputBinding:
        prefix: --input-dir
    output_dir:
      type: string
      default: stage-out
      inputBinding:
        prefix: --output-dir
  outputs:
    catalog_dir:
      type: Directory
      outputBinding:
        glob: stage-out
