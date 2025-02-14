import os
import time
import numpy as np

import solsticepy
from solsticepy.design_crs import CRS
from solsticepy.input import Parameters
from solsticepy.output_motab import output_matadata_motab, output_motab, read_motab


def set_param(inputs={}):
    '''
    set parameters
    '''

    pm=Parameters()
    for k, v in inputs.items():

        if hasattr(pm, k):
            setattr(pm, k, v)
        else:
            raise RuntimeError("invalid paramter '%s'"%(k,)) 

    pm.dependent_par()
    return pm

def run_simul(inputs={}):
    '''
    design the field base on performance of annual performance
    the annual performance is TMY DNI weighted
    '''

    pm=set_param(inputs)

    print('')
    print('Test inputs')
    for k, v in inputs.items():
        print(k, '=', getattr(pm, k))
    print('')
    print('')

    TIME=np.array([])
    print('')

    start=time.time()

    casedir=pm.casedir
    pm.saveparam(casedir)
    tablefile=casedir+'/OELT_Solstice.motab'
    if os.path.exists(tablefile):    
        print('')
        print('Load exsiting OELT')

    else:

        crs=CRS(latitude=pm.lat, casedir=casedir)

        crs.receiversystem(receiver=pm.rcv_type, rec_w=float(pm.W_rcv), rec_h=float(pm.H_rcv), rec_x=float(pm.X_rcv), rec_y=float(pm.Y_rcv), rec_z=float(pm.Z_rcv), rec_tilt=float(pm.tilt_rcv), rec_grid_w=int(pm.n_W_rcv), rec_grid_h=int(pm.n_H_rcv), rec_abs=float(pm.alpha_rcv))

        if pm.method==1:
            crs.heliostatfield(field=pm.field_type, hst_rho=pm.rho_helio, slope=pm.slope_error, hst_w=pm.W_helio, hst_h=pm.H_helio, tower_h=pm.H_tower, tower_r=pm.R_tower, hst_z=pm.Z_helio, num_hst=pm.n_helios, R1=pm.R1, fb=pm.fb, dsep=pm.dsep)
        else:
            crs.heliostatfield(field=pm.field_type, hst_rho=pm.rho_helio, slope=pm.slope_error, hst_w=pm.W_helio, hst_h=pm.H_helio, tower_h=pm.H_tower, tower_r=pm.R_tower, hst_z=pm.Z_helio, num_hst=pm.n_helios*2, R1=pm.R1, fb=pm.fb, dsep=pm.dsep)
 
        crs.yaml(dni=1000, sunshape=pm.sunshape, csr=pm.crs, half_angle_deg=pm.half_angle_deg, std_dev=pm.std_dev)

        if pm.field_type[-3:]=='csv':
            oelt, A_land=crs.annual_oelt(dni_des=pm.dni_des, num_rays=int(pm.n_rays), nd=int(pm.n_row_oelt), nh=int(pm.n_col_oelt))

        else:
            oelt, A_land=crs.field_design_annual(dni_des=pm.dni_des, num_rays=int(pm.n_rays), nd=int(pm.n_row_oelt), nh=int(pm.n_col_oelt), weafile=pm.wea_file, method=pm.method, Q_in_des=pm.Q_in_rcv, n_helios=pm.n_helios, zipfiles=False, gen_vtk=False, plot=False)

        if (A_land==0):    
            tablefile=None
        else:
                                          
            A_helio=pm.H_helio*pm.W_helio
            output_matadata_motab(table=oelt, field_type=pm.field_type, aiming='single', n_helios=crs.n_helios, A_helio=A_helio, eff_design=crs.eff_des, H_rcv=pm.H_rcv, W_rcv=pm.W_rcv, H_tower=pm.H_tower, Q_in_rcv=pm.Q_in_rcv, A_land=A_land, savedir=tablefile)
            end=time.time()
            print('')
            print('total time %.2f'%((end-start)/60.), 'min')
            np.savetxt(casedir+'/time.csv', np.r_[pm.n_rays, end-start], fmt='%.4f', delimiter=',')

    tablefile=tablefile.encode('utf-8')
    return tablefile

    
    
if __name__=='__main__':
    case="./test"
    Q_in_rcv=553e6 #W
    W_helio=12.015614841
    H_helio=12.015614841
    H_tower=183.331344997
    n_row_oelt=3
    n_col_oelt=5
    R1=40.
    fb=0.4
    W_rcv=14.9999995285
    H_rcv=18.6699994131
    n_W_rcv=50
    n_H_rcv=10
    n_rays=10e6
    rcv_type='cylinder'    

    field_type='surround'
    wea_file='../../SolarTherm/Data/Weather/gen3p3_Daggett_TMY3_EES.motab'
    inputs={'casedir': case, 'Q_in_rcv':Q_in_rcv, 'W_rcv':W_rcv, 'H_rcv':H_rcv, 'H_tower':H_tower, 'wea_file':wea_file, 'n_row_oelt':n_row_oelt, 'n_col_oelt': n_col_oelt, 'rcv_type': 'cylinder', 'R1':R1, 'fb':fb, 'field_type': field_type,"n_W_rcv":n_W_rcv,"n_H_rcv":n_H_rcv, "n_rays":n_rays }

    run_simul(inputs)


