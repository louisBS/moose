# Input file for an oxide growing outward on top of a steel 21-2N sample
# The growing oxide is not actually meshed as it's growth only depends on the Mn profile in the metal
# The variable is the Mn concentration [/nm^3]
# The length unit is the micrometer. The time unit is the hour
# there's 1 fixed interface (oxide/metal)
# The left part of the mesh is just here so that the M/O interface is not at the boundary
# The ICs are set as constants in each phase through ICs, no steady state
# Homogeneous T=700C for now.

[GlobalParams]
  order = FIRST
  family = LAGRANGE
[]

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 111
  ny = 20
  xmin = 0
  xmax = 110
  ymin = 0
  ymax = 20
  elem_type = QUAD4
[]

#[Mesh]
#  [./cmg]
#    type = CartesianMeshGenerator
#    dim = 2
#    dx = '100.1 10.01'
#    dy = '20'
#    ix = '100 60'
#    iy = '20'
#  [../]
#[]


[XFEM]
  qrule = volfrac
  output_cut_plane = true
[]

[UserObjects]
  [./fixed_cut_oxide_metal]
    type = LineSegmentCutSetUserObject
    cut_data = '100 0 100 20 0 0'
  [../]
  [./value_uo_m_ox]
    type = PointValueAtXFEMInterface
    variable = 'C_Mn'
    geometric_cut_userobject = 'fixed_cut_oxide_metal'
    execute_on = 'nonlinear'
    level_set_var = ls_metal_oxide
  [../]
  [./velocity_oxide]
    type = XFEMVelocitySteelOxLimDiff
    value_at_interface_uo = value_uo_m_ox
  [../]
#  [./fixed_cut_grad]
#    type = LineSegmentCutSetUserObject
#    cut_data = '90 0 90 20 0 0'
#  [../]
#  [./value_uo_grad]
#    type = PointValueAtXFEMInterface
#    variable = 'C_Mn'
#    geometric_cut_userobject = 'fixed_cut_grad'
#    execute_on = 'nonlinear'
#    level_set_var = ls_grad
#  [../]
[]

[Variables]
  [./C_Mn]
  [../]
[]

[ICs]
  [./ic_Mn]
    type = FunctionIC
    variable = C_Mn
    function = 'if(x<90,7.1445-2.1445/90*x,if(x<100,7.1445-7.1445/10*(x-90),0))'
  [../]
[]

[AuxVariables]
  [./ls_metal_oxide]
    order = FIRST
    family = LAGRANGE
  [../]
#  [./ls_grad]
#    order = FIRST
#    family = LAGRANGE
#  [../]
[]


[Constraints]
  [./oxide_metal_constraint]
    type = XFEMEqualValueAtInterface
    geometric_cut_userobject = 'fixed_cut_oxide_metal'
    use_displaced_mesh = false
    variable = C_Mn
    value = 0
    alpha = 1e5
  [../]
#  [./grad_constraint]
#    type = XFEMEqualValueAtInterface
#    geometric_cut_userobject = 'fixed_cut_grad'
#    use_displaced_mesh = false
#    variable = C_Mn
#    value = 5 #7.1445
#    alpha = 1e5
#  [../]
[]

[Kernels]
  [./diff]
    type = MatDiffusion
    variable = C_Mn
    diffusivity = 'diffusion_coefficient'
  [../]
  [./time]
    type = TimeDerivative
    variable = C_Mn
  [../]
[]

[AuxKernels]
  [./ls_metal_oxide]
    type = LineSegmentLevelSetAux
    line_segment_cut_set_user_object = 'fixed_cut_oxide_metal'
    variable = ls_metal_oxide
  [../]
#  [./ls_grad]
#    type = LineSegmentLevelSetAux
#    line_segment_cut_set_user_object = 'fixed_cut_grad'
#    variable = ls_grad
#  [../]
[]

[Materials]
  [./diffusivity_steel]
    type = GenericConstantMaterial
    prop_names = steel_diffusion_coefficient
    prop_values = 0.036
  [../]
  [./diffusivity_oxide]
    type = GenericConstantMaterial
    prop_names = oxide_diffusion_coefficient
    prop_values = 0.01
  [../]
  [./diff_combined]
    type = LevelSetBiMaterialReal
    levelset_negative_base = 'steel'
    levelset_positive_base = 'oxide'
    level_set_var = ls_metal_oxide
    prop_name = diffusion_coefficient
    outputs = exodus
  [../]
[]

[BCs]
# Define boundary conditions
  [./left_Mn]
    type = NeumannBC
    variable = C_Mn
    value = 0
    boundary = left
  [../]
#  [./left_Mn_init]
#    type = DirichletBC
#    variable = C_Mn
#    value = 7.1445
#    boundary = left
#  [../]
  [./right_u]
    type = DirichletBC
    variable = C_Mn
    value = 0 #13.3152
    boundary = right
  [../]
[]

#[Postprocessors]
#  [./position_ox_g]
#    type = PositionOfXFEMInterfacePostprocessor
#    value_at_interface_uo = value_uo_oxide
#    execute_on ='timestep_end final'
#  [../]
#[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type' # pc_factor_mat_solver_package' #-sub_pc_factor_shift_type -pc_factor_shift_amount
  petsc_options_value = 'lu' #mumps' #NONZERO 1e-6
  line_search = 'none'



  l_tol = 1e-3
  l_max_its = 10
  nl_max_its = 15
  nl_rel_tol = 1e-7
  nl_abs_tol = 1e-7

  start_time = 40
  dt = 10
  num_steps = 46
  max_xfem_update = 1
[]

#[Controls]
#  [./steady]
#    type = TimePeriod
#    #disable_objects = ' BCs::left_Mn' #Kernels::time  Constraints::oxide_metal_constraint
#    enable_objects = 'UserObjects::value_uo_grad UserObjects::fixed_cut_grad AuxKernels::ls_grad Constraints::grad_constraint' #BCs::left_Mn_init' #Constraints::oxide_metal_constraint_init
#    start_time = '40'
#    end_time = '50'
#  [../]
#  [./transient]
#    type = TimePeriod
#    #enable_objects = 'Kernels::time BCs::left_Mn' #  Constraints::oxide_metal_constraint
#    disable_objects = 'UserObjects::value_uo_grad UserObjects::fixed_cut_grad AuxKernels::ls_grad Constraints::grad_constraint BCs::left_Mn_init' #Constraints::oxide_metal_constraint_init
#    start_time = '50'
#    end_time = '500'
#  [../]
#[]

[Outputs]
  execute_on = timestep_end
  exodus = true
  [./console]
    type = Console
    output_linear = true
  [../]
  csv = true
  perf_graph = true
[]
