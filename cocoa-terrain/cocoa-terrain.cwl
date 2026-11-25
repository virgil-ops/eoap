cwlVersion: v1.2
$namespaces:
  s: https://schema.org/
s:softwareVersion: 1.0.1

$graph:
- class: Workflow
  id: cocoa-terrain
  label: Cocoa Terrain Suitability
  doc: >
    Downloads Copernicus DEM GLO-30 tiles for an area of interest, computes
    cocoa terrain suitability from elevation and slope thresholds, and
    creates a local COG with STAC metadata using three independent images.
  inputs:
    bbox:
      type: string
      label: Area of Interest
      doc: Bounding box in west,south,east,north order (EPSG:4326).
    max_elev:
      type: float
      default: 800
      label: Maximum elevation
      doc: Maximum elevation considered suitable, in metres.
    max_slope:
      type: float
      default: 15
      label: Maximum slope in degrees
      doc: Maximum slope considered suitable, in degrees.
    res:
      type: float
      default: 0.000833
      label: Output pixel size in degrees
      doc: Pixel size of the suitability raster in degrees.
  outputs:
    catalog_uri:
      type: Directory
      label: STAC Catalog URL
      doc: Local STAC Catalog directory; DPH stages the catalog and its assets.
      outputSource: stage_out/staged_dir
  steps:
    stage_in:
      run: "#stage-in"
      in:
        bbox: bbox
      out: [staged_dir]
    process:
      run: "#process"
      in:
        dem_dir: stage_in/staged_dir
        bbox: bbox
        max_elev: max_elev
        max_slope: max_slope
        res: res
      out: [results_dir]
    stage_out:
      run: "#stage-out"
      in:
        results_dir: process/results_dir
        bbox: bbox
        max_elev: max_elev
        max_slope: max_slope
        res: res
      out: [staged_dir]

- class: CommandLineTool
  id: stage-in
  requirements:
    DockerRequirement:
      dockerPull: docker.io/stormbreaker0/cocoa-terrain-stage-in:1.0.0
    NetworkAccess:
      networkAccess: true
    ResourceRequirement:
      ramMin: 256
      coresMin: 1
  baseCommand:
  - python
  - /app/stage_in.py
  inputs:
    bbox:
      type: string
      inputBinding:
        prefix: --bbox=
        separate: false
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
      dockerPull: docker.io/stormbreaker0/cocoa-terrain-process:1.0.0
    NetworkAccess:
      networkAccess: false
    ResourceRequirement:
      ramMin: 1024
      coresMin: 1
  baseCommand:
  - python
  - /app/process.py
  inputs:
    dem_dir:
      type: Directory
      inputBinding:
        prefix: --dem-dir
    bbox:
      type: string
      inputBinding:
        prefix: --bbox=
        separate: false
    max_elev:
      type: float
      inputBinding:
        prefix: --max-elev
    max_slope:
      type: float
      inputBinding:
        prefix: --max-slope
    res:
      type: float
      inputBinding:
        prefix: --res
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
      dockerPull: docker.io/stormbreaker0/cocoa-terrain-stage-out:1.0.0
    NetworkAccess:
      networkAccess: false
    ResourceRequirement:
      ramMin: 512
      coresMin: 1
  baseCommand:
  - python
  - /app/stage_out.py
  inputs:
    results_dir:
      type: Directory
      inputBinding:
        prefix: --results-dir
    bbox:
      type: string
      inputBinding:
        prefix: --bbox=
        separate: false
    max_elev:
      type: float
      inputBinding:
        prefix: --max-elev
    max_slope:
      type: float
      inputBinding:
        prefix: --max-slope
    res:
      type: float
      inputBinding:
        prefix: --res
    outdir:
      type: string
      default: stage-out
      inputBinding:
        prefix: --outdir
  outputs:
    staged_dir:
      type: Directory
      outputBinding:
        glob: stage-out
