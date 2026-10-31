"""Reproducible original 3D gallery sculptures. Run with Blender 4.3+ --background.
All geometry is authored here; original reference illustrations are never modified.
Coordinates: X right, -Y front, Z up. Exported glTF uses Godot +Y up / +Z front.
"""
import bpy, math, random, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/models/v13'
OUT.mkdir(parents=True,exist_ok=True)
random.seed(1300)
PARTS=[]; SKIN=[]; BONE='spine'; M={}; TEXTURES={}

# Physical material microstructure. These are mathematical tile textures, not
# edited source artwork or images being presented as the user's drawings.
def detail_texture(kind):
    if kind in TEXTURES: return TEXTURES[kind]
    size=256; rng=np.random.default_rng(1300+{'skin':1,'fabric':2,'leather':3,'stone':4}[kind])
    y,x=np.mgrid[:size,:size]/size
    if kind=='fabric': h=.35*np.sin(x*math.tau*82)*np.sin(y*math.tau*82)+rng.random((size,size))*.1
    elif kind=='leather':
        h=rng.random((size,size))
        for i in range(3): h=(h+np.roll(h,1,0)+np.roll(h,-1,0)+np.roll(h,1,1)+np.roll(h,-1,1))/5
    elif kind=='stone':
        h=np.zeros((size,size))
        for freq,amp in [(4,.4),(13,.2),(37,.1),(97,.04)]: h+=amp*np.sin(x*math.tau*freq+np.sin(y*math.tau*freq))*np.cos(y*math.tau*freq*.75)
    else: h=rng.random((size,size))*.15+np.sin(x*math.tau*61)*np.sin(y*math.tau*59)*.05
    dx=(np.roll(h,-1,1)-np.roll(h,1,1))*1.2;dy=(np.roll(h,-1,0)-np.roll(h,1,0))*1.2
    normal=np.stack((-dx,-dy,np.ones_like(dx)),axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
    rgba=np.ones((size,size,4),dtype=np.float32);rgba[:,:,:3]=normal*.5+.5
    im=bpy.data.images.new('detail_'+kind,width=size,height=size)
    im.colorspace_settings.name='Non-Color';im.pixels.foreach_set(rgba.ravel());im.pack()
    TEXTURES[kind]=im;return im

def mat(name,color,rough=.55,metal=0,glow=0,detail=None):
    c=tuple((int(color[i:i+2],16)/255)**2.2 for i in (0,2,4))
    m=bpy.data.materials.new(name);m.diffuse_color=(*c,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*c,1)
    bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metal
    bs.inputs['Specular IOR Level'].default_value=.28 if metal==0 else .5
    if glow: bs.inputs['Emission Color'].default_value=(*c,1);bs.inputs['Emission Strength'].default_value=glow
    if detail:
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=detail_texture(detail)
        nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.24 if detail!='stone' else .5
        m.node_tree.links.new(tex.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
    return m

def attach(ob,name,material,bone=None,skin=False):
    ob.name=name;ob.data.materials.clear();ob.data.materials.append(material)
    ob['bone']=bone or BONE
    if ob.type=='MESH':
        for p in ob.data.polygons:p.use_smooth=True
    PARTS.append(ob)
    if skin:SKIN.append(ob)
    return ob

def ell(name,at,size,material,bone=None,skin=False,segments=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=16,location=at)
    ob=bpy.context.object;ob.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return attach(ob,name,material,bone,skin)

def cube(name,at,size,material,bone=None,bevel=.02):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at);ob=bpy.context.object;ob.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=ob.modifiers.new('Tailored rounded edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return attach(ob,name,material,bone)

def loft(name,sections,material,bone=None,n=32,skin=False,faceted=False):
    # sections: center and elliptical cross-section radii in the XY plane.
    verts=[];faces=[]
    for j,(x,y,z,rx,ry) in enumerate(sections):
        for i in range(n):
            a=math.tau*i/n
            ripple=1+.012*math.sin(a*5+j*.7)
            verts.append((x+math.cos(a)*rx*ripple,y+math.sin(a)*ry*ripple,z))
    for j in range(len(sections)-1):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.extend([tuple(reversed(range(n))),tuple((len(sections)-1)*n+i for i in range(n))])
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
    uv=me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi=me.loops[li].vertex_index;uv.data[li].uv=((vi%n)/n,(vi//n)/(len(sections)-1))
    attach(ob,name,material,bone,skin)
    if faceted:
        for p in me.polygons:p.use_smooth=False
    return ob

def tube(name,points,radii,material,bone=None,sides=12,skin=False,flatten=1.0):
    verts=[];faces=[]
    for j,point in enumerate(points):
        p=Vector(point)
        tangent=Vector(points[min(j+1,len(points)-1)])-Vector(points[max(0,j-1)])
        tangent.normalize();u=tangent.cross(Vector((0,1,0)))
        if u.length < .01:u=tangent.cross(Vector((1,0,0)))
        u.normalize();v=tangent.cross(u).normalized()
        for i in range(sides):
            angle=math.tau*i/sides;verts.append(p+radii[j]*(u*math.cos(angle)+v*math.sin(angle)*flatten))
    for j in range(len(points)-1):
        for i in range(sides):faces.append((j*sides+i,j*sides+(i+1)%sides,(j+1)*sides+(i+1)%sides,(j+1)*sides+i))
    faces.extend([tuple(reversed(range(sides))),tuple((len(points)-1)*sides+i for i in range(sides))])
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
    uv=me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi=me.loops[li].vertex_index;uv.data[li].uv=((vi%sides)/sides,(vi//sides)/max(1,len(points)-1))
    return attach(ob,name,material,bone,skin)

def line(name,points,radius,material,bone=None):
    # Smooth Bezier surface tubes for seams, hair, scars and molten fissures.
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.resolution_u=5
    curve.bevel_depth=radius;curve.bevel_resolution=2
    spline=curve.splines.new('BEZIER');spline.bezier_points.add(len(points)-1)
    for i,(p,co) in enumerate(zip(spline.bezier_points,points)):
        p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
        p.radius=1 if i<len(points)-1 else .35
    ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob.select_set(False)
    return attach(ob,name,material,bone)

def spike(name,points,radii,material,bone=None,sides=10):
    ob=tube(name,points,radii,material,bone,sides)
    if material==M.get('gemstone'):
        for p in ob.data.polygons:p.use_smooth=False
    return ob

def ring(name,at,radius,wire,material,bone=None,rotation=None,scale=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,location=at,major_radius=radius,minor_radius=wire)
    ob=bpy.context.object
    if rotation:ob.rotation_euler=rotation
    if scale:ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return attach(ob,name,material,bone)

def sculpt_union(objects,name,material,voxel=.018):
    if not objects:return None
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();ob=bpy.context.object
    mod=ob.modifiers.new('Continuous sculpt surface','REMESH');mod.mode='VOXEL';mod.voxel_size=voxel;mod.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    smooth=ob.modifiers.new('Sculpt relaxation','SMOOTH');smooth.factor=1.1;smooth.iterations=3;bpy.ops.object.modifier_apply(modifier=smooth.name)
    for old in objects:
        if old in PARTS:PARTS.remove(old)
    ob.name=name;ob.data.materials.clear();ob.data.materials.append(material);PARTS.append(ob)
    # Planar/cylindrical UVs for microstructure on the remeshed surface.
    uv=ob.data.uv_layers.new(name='UVMap')
    for poly in ob.data.polygons:
        poly.use_smooth=True
        for li in poly.loop_indices:
            p=ob.matrix_world@ob.data.vertices[ob.data.loops[li].vertex_index].co
            uv.data[li].uv=(math.atan2(p.y,p.x)/math.tau,p.z*1.8)
    ob['weighted_body']=True
    return ob

CONFIG={
'sharkbyte':dict(skin='4a6976',accent='279edb',cloth='ddd8ca',kind='shark',width=1.05),
'bullet':dict(skin='a88470',accent='df4c29',cloth='222830',kind='human',width=1.2),
'nachtelf':dict(skin='b8a39d',accent='e83d30',cloth='201c28',kind='elf',width=.98),
'poisonboy':dict(skin='bca07b',accent='8cd337',cloth='1d2926',kind='human',width=.95),
'spinegrin':dict(skin='718849',accent='a4da41',cloth='242c22',kind='lizard',width=1.02),
'chainveil':dict(skin='d7bdba',accent='ef426f',cloth='211b28',kind='woman',width=.84),
'cheese_rat':dict(skin='39383e',accent='c92531',cloth='bb962c',kind='rat',width=.92),
'lava_stone':dict(skin='292d31',accent='ff5c16',cloth='303237',kind='rock',width=1.27),
'crystal_fang':dict(skin='292533',accent='ef66c0',cloth='211f2d',kind='wolf',width=1.12),
'phoenix_reign':dict(skin='a44c24',accent='ff9f2b',cloth='2a2020',kind='bird',width=1.02),
}

def materials(cfg):
    return dict(skin=mat('skin_'+cfg['kind'],cfg['skin'],.65,detail='stone' if cfg['kind']=='rock' else 'skin'),
        cloth=mat('woven_clothing',cfg['cloth'],.83,detail='fabric'),
        leather=mat('worn_black_leather','171c24',.54,detail='leather'),
        red=mat('oxblood_leather','5f1728',.44,detail='leather'),
        stitch=mat('tailoring_stitch','938574',.83),
        metal=mat('brushed_gunmetal','59626d',.29,.8),
        gold=mat('antique_gold','9b7945',.3,.76),
        dark=mat('deep_occlusion','0b111a',.72),
        eye=mat('iris_energy',cfg['accent'],.25,.15,1.4),
        accent=mat('signature_energy',cfg['accent'],.26,.22,.65),
        ivory=mat('ivory_teeth_claws','dccca9',.44),
        hair=mat('hair_ebony','12151d',.48,detail='leather'),
        hair_edge=mat('hair_highlights','37313b',.46),
        denim=mat('indigo_denim','293f58' if cfg['kind']=='rat' else '202832',.86,detail='fabric'),
        red_fabric=mat('oxblood_cotton','681d2b',.82,detail='fabric'),
        lip=mat('lips_lid_detail','5f343b',.54),
        sclera=mat('eye_sclera','c7c9b7',.3),
        gemstone=mat('faceted_crystal',cfg['accent'],.21,.30,.12),
        natural_iris=mat('natural_iris','66533f',.45))

JOINTS={}
def body(cfg,ident):
    global BONE,JOINTS
    BONE='spine';w=cfg['width'];female=cfg['kind']=='woman'
    # Swept, elliptical anatomy rather than stacked primitive ball joints.
    loft('sculpted_core',[(0,0,1.03,.18*w,.13),(0,0,1.17,.23*w,.16),(0,0,1.36,.17*w if female else .23*w,.145),(0,0,1.55,.19*w if female else .28*w,.17),(0,0,1.76,.26*w if female else .35*w,.19),(0,0,1.92,.30*w,.16),(0,0,2.01,.12,.10),(0,0,2.13,.09,.085)],M['skin'],skin=True)
    for side in [-1,1]:
        if ident in ['spinegrin','lava_stone','crystal_fang']:
            ell('pectoralis',(side*.15*w,-.12,1.78),(.18*w,.09,.10),M['skin'],skin=True)
        for z in [1.44,1.55,1.64]:ell('abdominal_plane',(side*.075,-.135,z),(.075,.04,.055),M['skin'],skin=True)
        shoulder=(side*.34*w,0,1.91);elbow=(side*.51*w,-.035,1.58);wrist=(side*.57*w,-.12,1.28)
        if ident in ['nachtelf','poisonboy'] and side==1:elbow=(side*.51,-.025,1.64);wrist=(side*.68,-.30,1.69)
        hip=(side*.15*w,.015,1.14);knee=(side*.20*w,-.025,.64);ankle=(side*.23*w,-.02,.17)
        suffix='L' if side<0 else 'R'
        JOINTS['upper_arm_'+suffix]=(shoulder,elbow,'spine');JOINTS['forearm_'+suffix]=(elbow,wrist,'upper_arm_'+suffix)
        hand_end=tuple(Vector(wrist)+Vector((side*.015,-.025,-.14)))
        JOINTS['hand_'+suffix]=(wrist,hand_end,'forearm_'+suffix)
        JOINTS['thigh_'+suffix]=(hip,knee,'pelvis');JOINTS['shin_'+suffix]=(knee,ankle,'thigh_'+suffix)
        JOINTS['foot_'+suffix]=(ankle,(ankle[0],-.28,.11),'shin_'+suffix)
        for name,p,q,radii in [('upper_arm',shoulder,elbow,[.13,.16,.12,.085]),('forearm',elbow,wrist,[.09,.12,.095,.065])]:
            pts=[Vector(p).lerp(Vector(q),i/3) for i in range(4)]
            tube('anatomical_'+name,pts,[r*w for r in radii],M['skin'],name+'_'+suffix,20,True)
        # Clothing naturally covers the hip / knee transitions.
        pants=M['cloth'] if ident not in ['bullet','cheese_rat'] else M['denim']
        if female:pants=M['skin']
        pts=[Vector(hip),Vector(hip).lerp(Vector(knee),.38),Vector(hip).lerp(Vector(knee),.8),Vector(knee),Vector(knee).lerp(Vector(ankle),.35),Vector(knee).lerp(Vector(ankle),.8),Vector(ankle)]
        leg=tube('continuous_tailored_leg',pts,[r*w for r in [.15,.17,.13,.108,.115,.08,.066]],pants,'thigh_'+suffix,32)
        leg['weighted_body']=True
        hand(wrist,suffix,side,cfg)
        footwear(ankle,suffix,ident,cfg)
    # Skin is one continuous remeshed sculpture; weight by bone distance later.
    # Main head added before this union, with facial details layered afterward.


def hand(wrist,suffix,side,cfg):
    p=Vector(wrist);bn='hand_'+suffix
    ell('hand_metacarpals',p+Vector((0,-.015,-.065)),(.078,.052,.095),M['skin'],bn,True)
    for i in range(4):
        x=p.x+(i-1.5)*.035
        pts=[(x,p.y-.025,p.z-.09),(x,p.y-.07,p.z-.15),(x,p.y-.045,p.z-.18)]
        tube('articulated_finger',pts,[.021,.019,.014],M['skin'],bn,10,True)
        if cfg['kind'] in ['wolf','lizard','bird']:
            spike('finger_claw',[pts[-1],(x,p.y-.095,p.z-.22)],[.016,.001],M['ivory'],bn)
        else:ell('finger_nail',(x,p.y-.062,p.z-.155),(.013,.006,.02),M['ivory'],bn)
    tube('opposed_thumb',[p+Vector((-side*.06,-.02,-.035)),p+Vector((-side*.09,-.08,-.08)),p+Vector((-side*.05,-.09,-.12))],[.03,.026,.019],M['skin'],bn,12,True)

def footwear(ankle,suffix,ident,cfg):
    x,y,z=ankle;bn='foot_'+suffix
    if cfg['kind'] in ['wolf','bird']:
        ell('digitigrade_foot',(x,-.115,.105),(.12,.20,.10),M['skin'],bn)
        for i in range(3):
            xx=x+(i-1)*.07
            ell('clawed_toe',(xx,-.265,.09),(.045,.105,.045),M['skin'],bn)
            spike('foot_talon',[(xx,-.31,.10),(xx,-.40,.08),(xx,-.43,.045)],[.035,.024,.001],M['ivory'],bn)
        return
    sole=M['red'] if ident=='cheese_rat' else M['dark']
    cube('layered_rubber_outsole',(x,-.11,.055),(.235,.44,.09),sole,bn,.025)
    cube('welt',(x,-.105,.097),(.23,.425,.025),M['stitch'],bn,.012)
    ell('leather_toe_box',(x,-.20,.145),(.115,.18,.065),M['leather'],bn)
    loft('boot_shaft',[(x,0,.10,.105,.14),(x,0,.20,.10,.12),(x,0,.30,.084,.09)],M['leather'],bn,n=24)
    for i in range(5):
        yy=-.19+i*.035;zz=.19+i*.013
        line('cross_lace',[(x-.06,yy,zz),(x+.06,yy+.02,zz+.005)],.004,M['stitch'],bn)
        for side in [-1,1]:ell('eyelet',(x+side*.066,yy,zz),(.008,.008,.004),M['metal'],bn,segments=12)
    for i in range(5):cube('sole_tread',(x,-.24+i*.075,.016),(.21,.026,.026),M['dark'],bn,.004)
    if ident=='chainveil':
        loft('tall_laced_boot',[(x,-.025,.25,.10,.14),(x,-.025,.4,.12,.15),(x,-.025,.59,.12,.15),(x,-.025,.68,.115,.14)],M['leather'],'shin_'+suffix)
        for i in range(6):line('boot_laces',[(x-.05,-.108,.3+i*.055),(x+.05,-.108,.33+i*.055)],.004,M['stitch'],'shin_'+suffix)


def head(cfg,ident):
    kind=cfg['kind'];human=kind in ['human','woman','elf','rock'];bn='head'
    if human:
        loft('cranial_sculpt',[(0,-.005,2.095,.09,.075),(0,-.014,2.14,.12,.095),(0,0,2.22,.14,.115),(0,.01,2.34,.16,.135),(0,.02,2.44,.15,.13),(0,.03,2.50,.10,.095),(0,.03,2.525,.01,.01)],M['skin'],bn,skin=True)
        for side in [-1,1]:
            ell('cheekbone',(side*.10,-.07,2.27),(.045,.025,.045),M['skin'],bn,True)
            ell('ear',(side*.15,.015,2.30),(.03,.039,.065),M['skin'],bn,True)
        # Nose bridge, nostrils and sculpted planes rather than a muzzle.
        tube('nasal_bridge',[(0,-.105,2.35),(0,-.143,2.28),(0,-.166,2.26)],[.022,.026,.023],M['skin'],bn,12,True)
        ell('nose_tip',(0,-.16,2.265),(.035,.027,.022),M['skin'],bn,True)
        if kind=='elf':
            for side in [-1,1]:spike('pointed_elf_ear',[(side*.14,.02,2.30),(side*.24,.055,2.40),(side*.28,.08,2.45)],[.055,.025,.001],M['skin'],bn)
    else:
        ell('creature_cranium',(0,.015,2.32),(.19,.165,.22),M['skin'],bn,True)
        if kind=='shark':
            ell('broad_shark_rostrum',(0,-.17,2.37),(.19,.22,.095),M['skin'],bn,True)
            ell('shark_lower_jaw',(0,-.12,2.22),(.15,.18,.06),M['skin'],bn,True)
        elif kind in ['wolf','rat','lizard']:
            ell('tapered_muzzle',(0,-.14,2.265),(.13 if kind=='wolf' else .095,.22,.095),M['skin'],bn,True)
            ell('lower_jaw',(0,-.13,2.19),(.12,.18,.05),M['skin'],bn,True)
            if kind=='rat':
                for side in [-1,1]:
                    ell('rat_ear',(side*.19,.02,2.47),(.10,.034,.125),M['skin'],bn,True)
                    ell('inner_rat_ear',(side*.19,-.018,2.47),(.072,.01,.09),M['lip'],bn)
            if kind=='wolf':
                for side in [-1,1]:spike('wolf_ear',[(side*.14,.025,2.45),(side*.20,.035,2.68)],[.105,.002],M['skin'],bn)
        elif kind=='bird':
            spike('curved_hawk_beak',[(0,-.12,2.32),(0,-.29,2.28),(0,-.34,2.17)],[.09,.055,.001],M['gold'],bn,sides=16)
            for i in range(6):spike('feather_crest',[(0,.04+i*.015,2.47),(0,.17+i*.02,2.64+i*.02),(0,.25+i*.025,2.57+i*.02)],[.07,.04,.001],M['accent'] if i%2 else M['skin'],bn)
    return human


def face_details(cfg,ident,human):
    bn='head';kind=cfg['kind']
    if kind=='rock':
        for side in [-1,1]:
            ell('furnace_eye',(side*.066,-.126,2.34),(.036,.018,.013),M['eye'],bn)
        return
    for side in [-1,1]:
        x=side*(.067 if human else .14);y=-.113 if human else (-.19 if kind=='shark' else -.15);z=2.34 if human else (2.435 if kind=='shark' else 2.40)
        if human:
            y=-.105
            ell('eye_socket',(x,y-.006,z),(.038,.014,.016),M['dark'],bn)
            ell('eye_white',(x,y-.014,z),(.030,.012,.009),M['sclera'],bn)
            iris_material=M['eye'] if ident=='nachtelf' else M['natural_iris']
            ell('iris',(x-side*.004,y-.026,z),(.010,.003,.009),iris_material,bn,segments=16)
            ell('pupil',(x-side*.004,y-.029,z),(.005,.002,.007),M['dark'],bn,segments=16)
            ell('corneal_catchlight',(x-.003,y-.031,z+.003),(.002,.001,.002),M['ivory'],bn,segments=12)
            line('upper_eyelid',[(x-.030,y-.019,z),(x,y-.028,z+.010),(x+.030,y-.019,z)],.0045,M['skin'],bn)
            line('lower_eyelid',[(x-.028,y-.018,z),(x,y-.026,z-.009),(x+.028,y-.018,z)],.003,M['skin'],bn)
            line('brow_ridge',[(x-side*.030,y-.008,z+.014),(x,y-.008,z+.023),(x+side*.036,y+.005,z+.024)],.006,M['hair'],bn)
        else:
            ell('eye_socket',(x,y-.007,z),(.044,.020,.022),M['dark'],bn)
            ell('eye_white',(x,y-.018,z),(.033,.016,.014),M['eye'],bn)
            ell('pupil',(x-side*.006,y-.035,z),(.007,.003,.011),M['dark'],bn,segments=16)
            line('creature_brow',[(x-side*.032,y-.010,z+.017),(x,y-.008,z+.032),(x+side*.037,y+.005,z+.026)],.012,M['skin'],bn)
    if human:
        for side in [-1,1]:ell('nostril',(side*.019,-.176,2.255),(.007,.003,.005),M['dark'],bn,segments=12)
        line('mouth_seam',[(-.05,-.092,2.205),(0,-.112,2.201),(.05,-.092,2.205)],.0025,M['dark'],bn)
        line('lower_lip',[(-.035,-.096,2.199),(0,-.112,2.19),(.035,-.096,2.199)],.0035,M['lip'],bn)
        if ident=='bullet':
            for i in range(24):
                a=random.uniform(-1,1);x=a*.07;z=random.uniform(2.14,2.19)
                line('stubble',[(x,-.095,z),(x,-.101,z+.012)],.002,M['hair'],bn)
            line('old_eyebrow_scar',[(-.086,-.14,2.39),(-.07,-.15,2.35)],.003,M['ivory'],bn)
        return
    if kind!='bird':
        y=-.29 if kind=='shark' else -.32
        line('mouth_cleft',[(-.12,y+.045,2.25),(0,y,2.235),(.12,y+.045,2.25)],.014,M['dark'],bn)
        for i in range(11):
            x=(i-5)*.021;yy=y+.04*(x/.12)**2
            spike('upper_fang',[(x,yy,2.256),(x,yy-.003,2.215)],[.009,.0007],M['ivory'],bn)
        if kind=='rat':
            for side in [-1,1]:
                cube('rat_incisor',(side*.015,-.333,2.225),(.025,.02,.046),M['ivory'],bn,.004)
                for i in range(3):line('whisker',[(side*.065,-.29,2.26),(side*.19,-.32,2.25+i*.025),(side*.30,-.30,2.23+i*.04)],.0015,M['stitch'],bn)
        if kind in ['wolf','rat']:ell('animal_nose',(0,-.344,2.29),(.065,.036,.037),M['dark'],bn)
        if kind=='shark':
            for side in [-1,1]:
                for i in range(3):line('shark_gill',[(side*.155,.02,2.15-i*.035),(side*.18,.015,2.15-i*.035)],.004,M['dark'],bn)


def hair(ident):
    if ident not in ['bullet','nachtelf','poisonboy','chainveil']:return
    bn='head'
    # Layered tapered locks with smaller highlighted grooves.
    long=ident in ['nachtelf','chainveil'];count=76 if long else 44
    loft('scalp_hair_mass',[(0,.025,2.385,.159,.14),(0,.025,2.44,.164,.145),(0,.03,2.52,.10,.10),(0,.03,2.55,.01,.01)],M['hair'],bn)
    for i in range(count):
        angle=math.tau*i/count
        x=math.cos(angle)*.13;y=.025+math.sin(angle)*.11
        start=(x*.6,y*.6,2.50+random.random()*.025)
        if long:
            end=(x*1.9+math.sin(i)*.07,.10+abs(y)*1.5,1.35+random.random()*.58)
            middle=(x*1.35,.10+abs(y),2.15)
            points=[start,(x*1.1,y,2.40),middle,end]
            radii=[.019,.029,.025,.001]
        else:
            points=[start,(x,y,2.47),(x+(-.06 if ident=='bullet' else .01),y+.025,2.30+random.random()*.13)]
            radii=[.020,.032,.001]
        tube('layered_hair_lock',points,radii,M['hair'] if i%6 else M['hair_edge'],bn,10,flatten=.5)
        if i%3==0:line('hair_striation',[(p[0]-.008,p[1]-.008,p[2]) for p in points],.002,M['hair_edge'],bn)
    # A few swept forehead locks, leaving eyes readable.
    for i in range(6):
        x=(i-2.5)*.034
        tube('swept_fringe',[(x,.015,2.51),(x-.035,-.11,2.48),(x-.045,-.13,2.36+i*.007)],[.015,.020,.001],M['hair'],'head',10,flatten=.5)


def belt(w):
    loft('waist_belt',[(0,0,1.15,.24*w,.17),(0,0,1.23,.24*w,.17)],M['leather'],'pelvis')
    cube('belt_buckle',(0,-.183,1.19),(.09,.024,.064),M['metal'],'pelvis',.006)
    cube('buckle_inset',(0,-.198,1.19),(.06,.014,.037),M['dark'],'pelvis',.003)
    for side in [-1,1]:
        for i in range(3):ell('belt_stud',(side*(.07+i*.035),-.178,1.19),(.007,.007,.007),M['gold'],'pelvis',segments=12)


def outfit(cfg,ident):
    w=cfg['width'];female=cfg['kind']=='woman'
    belt(w)
    if not female:
        trousers=M['denim'] if ident in ['bullet','cheese_rat'] else M['cloth']
        loft('trouser_pelvis',[(0,.01,1.01,.21*w,.16),(0,0,1.13,.25*w,.175),(0,0,1.22,.24*w,.175)],trousers,'pelvis')
    if ident in ['sharkbyte','nachtelf','poisonboy','cheese_rat','bullet','chainveil','phoenix_reign']:
        cloth=M['cloth'] if ident in ['poisonboy','cheese_rat'] else M['leather']
        if ident=='bullet':cloth=M['red_fabric']
        if female:
            loft('structured_corset',[(0,0,1.20,.25,.20),(0,0,1.34,.21,.19),(0,-.015,1.55,.25,.21),(0,-.02,1.72,.29,.23)],M['leather'])
            loft('leather_shorts',[(0,0,1.04,.26,.20),(0,0,1.22,.25,.20)],M['leather'],'pelvis')
            for x in [-.13,-.07,0,.07,.13]:
                line('corset_boning',[(x,-.198*math.sqrt(1-(x/.24)**2)-.008,1.23),(x*.85,-.005-.20*math.sqrt(1-(x*.85/.225)**2)-.008,1.43),(x*1.4,-.02-.225*math.sqrt(1-(x*1.4/.28)**2)-.008,1.68)],.004,M['gold'])
            for i in range(7):
                z=1.25+i*.055;y=-.216-(z-1.25)*.065
                for side in [-1,1]:ell('corset_eyelet',(side*.045,y,z),(.007,.004,.007),M['metal'])
                line('corset_cross_lace',[(-.04,y-.005,z),(.04,y-.009,z+.035)],.0027,M['stitch'])
                line('corset_cross_lace',[(.04,y-.005,z),(-.04,y-.009,z+.035)],.0027,M['stitch'])
        else:
            # A single open-front garment shell with real thickness and lapels.
            closed=ident in ['bullet','cheese_rat','poisonboy']
            rows=[(1.24,.25*w,.185),(1.44,.255*w,.195),(1.68,.32*w,.22),(1.85,.37*w,.225),(1.96,.31*w,.165)]
            n=48;verts=[];faces=[];opening=.06 if closed else .62
            for z,rx,ry in rows:
                for i in range(n+1):
                    angle=-math.pi/2+opening/2+(math.tau-opening)*i/n
                    verts.append((rx*math.cos(angle),ry*math.sin(angle),z-(.065*max(0,-math.sin(angle))**4 if closed and z==1.96 else 0)))
            for j in range(len(rows)-1):
                for i in range(n):faces.append((j*(n+1)+i,j*(n+1)+i+1,(j+1)*(n+1)+i+1,(j+1)*(n+1)+i))
            me=bpy.data.meshes.new('GarmentShell');me.from_pydata(verts,[],faces);me.update()
            jacket=bpy.data.objects.new('continuous_tailored_jacket',me);bpy.context.collection.objects.link(jacket);attach(jacket,jacket.name,cloth)
            uv=me.uv_layers.new(name='UVMap')
            for poly in me.polygons:
                for li in poly.loop_indices:
                    vi=me.loops[li].vertex_index;uv.data[li].uv=((vi%(n+1))/n,(vi//(n+1))/(len(rows)-1))
            bpy.context.view_layer.objects.active=jacket
            mod=jacket.modifiers.new('cloth_thickness','SOLIDIFY');mod.thickness=.014;bpy.ops.object.modifier_apply(modifier=mod.name)
            for side in [-1,1]:
                edge=[(side*rx*math.sin(opening/2),-ry*math.cos(opening/2)-.01,z) for z,rx,ry in rows]
                line('front_stitching',edge,.0035,M['stitch'])
                if not closed:line('folded_lapel',[(side*.15,-.15,2.0),(side*.21,-.24,1.87),(side*.10,-.232,1.65)],.018,M['red'] if ident=='nachtelf' else cloth)
            if ident!='bullet':
                for suffix in ['L','R']:
                    p,q,_=JOINTS['upper_arm_'+suffix];_,r,_=JOINTS['forearm_'+suffix]
                    pts=[Vector(p),Vector(p).lerp(Vector(q),.45),Vector(q),Vector(q).lerp(Vector(r),.5),Vector(r)]
                    sleeve=tube('continuous_jacket_sleeve',pts,[v*w for v in [.155,.17,.118,.117,.083]],cloth,'upper_arm_'+suffix,32)
                    sleeve['weighted_body']=True
        for side in [-1,1]:
            suffix='L' if side<0 else 'R';p,q,_=JOINTS['forearm_'+suffix]
            wrist=Vector(q)
            for j in range(2):
                ring('wrist_band',wrist+Vector((0,0,j*.035)),.078,.009,M['metal'],'forearm_'+suffix)
    # Folds, seams and fitted knee panels make actual clothing, not bare tubes.
    for suffix in ['L','R']:
        hip,knee,_=JOINTS['thigh_'+suffix];side=-1 if suffix=='L' else 1
        if not female:
            for j in range(5):
                z=.75+j*.065;x=knee[0]
                line('fabric_compression_fold',[(x-.08,-.088,z),(x,-.123,z+.02),(x+.08,-.09,z+.01)],.007,M['cloth'] if ident!='cheese_rat' else M['denim'],'thigh_'+suffix)
            line('trouser_outseam',[(hip[0]+side*.14,0,1.14),(knee[0]+side*.13,0,.73)],.003,M['stitch'],'thigh_'+suffix)
        else:
            # Lace garters, side-draped skirt panels, chains and platform boots.
            for z in [.87,.92]:ring('lace_garter',(hip[0],0,z),.14,.009,M['leather'],'thigh_'+suffix)
            tube('draped_skirt_panel',[(side*.22,.08,1.27),(side*.28,.15,1.02),(side*.33,.18,.76)],[.11,.105,.001],M['red'],'pelvis',12)
    if ident in ['poisonboy','nachtelf']:
        center=Vector((.68,-.30,1.93))
        ell('conjured_energy_core',center,(.07,.07,.07),M['accent'],'hand_R')
        for i in range(3):
            pts=[]
            for j in range(17):
                a=math.tau*j/16
                pts.append(center+Vector((.13*math.cos(a),.10*math.sin(a+i),.13*math.sin(a))))
            line('conjuring_filament',pts,.0035,M['accent'],'hand_R')
    if ident=='poisonboy':
        loft('slouch_beanie',[(0,.03,2.40,.17,.15),(0,.04,2.50,.17,.16),(0,.06,2.58,.125,.13),(0,.07,2.60,.04,.07)],M['cloth'],'head')
        ring('beanie_rib',(0,.03,2.43),.165,.014,M['accent'],'head',scale=(1,.88,.6))
        for side in [-1,1]:line('hood_drawcord',[(side*.11,-.19,1.96),(side*.12,-.22,1.66)],.005,M['stitch'])
        skull((0,-.213,1.72),.055,'spine')
        for i in range(3):
            ring('belt_chain',(w*.18,-.16-i*.012,1.04-i*.04),.026,.006,M['metal'],'pelvis',rotation=(math.pi/2,0,0))
    if ident=='bullet':
        skull((0,-.244,1.72),.063,'spine')
        for side in [-1,1]:
            spike('bull_crest_horn',[(side*.04,-.246,1.75),(side*.10,-.249,1.80),(side*.105,-.248,1.84)],[.012,.009,.001],M['gold'],'spine')
        line('bronze_necklace',[(-.14,-.13,1.98),(-.12,-.235,1.87),(0,-.257,1.78),(.12,-.235,1.87),(.14,-.13,1.98)],.006,M['gold'])
        for side in [-1,1]:
            suffix='L' if side<0 else 'R';p0,p1,_=JOINTS['upper_arm_'+suffix]
            a=Vector(p0);b=Vector(p1);tangent=(b-a).normalized();u=tangent.cross(Vector((0,1,0))).normalized();v=tangent.cross(u).normalized()
            for i in range(10):
                pts=[]
                for j in range(7):
                    t=.2+i*.043+.015*math.sin(j*2);angle=-.8+j*.26
                    center=a.lerp(b,t);radius=(.155-.05*abs(t-.35))*w+.006
                    pts.append(center+u*math.sin(angle)*radius+v*math.cos(angle)*radius)
                line('tribal_arm_wrap',pts,.003,M['dark'],'upper_arm_'+suffix)
        for side in [-1,1]:
            p,q,_=JOINTS['upper_arm_'+('L' if side<0 else 'R')]
            for j in range(6):
                z=1.65+j*.033;x=side*(.47*w+.018*math.sin(j*2))
                line('arm_tribal_ink',[(x-side*.04,-.118,z),(x,-.151,z+.014),(x+side*.04,-.12,z+.005)],.004,M['dark'],'upper_arm_'+('L' if side<0 else 'R'))
    if ident=='cheese_rat':
        for i in range(15):
            x=random.uniform(-.21,.21);z=random.uniform(1.35,1.83)
            ell('cheese_print_spot',(x,-.203,z),(.012,.003,.016),M['dark'])
        for z in [1.32,1.44,1.56,1.68,1.80]:ell('shirt_button',(0,-.22,z),(.009,.006,.009),M['ivory'])
    if ident=='nachtelf':
        for side in [-1,1]:
            tube('long_coat_tail',[(side*.18,.03,1.35),(side*.28,.13,.95),(side*.34,.24,.42)],[.16,.19,.025],M['red'],'pelvis',16)
            for i in range(5):
                p=(side*(.32+i*.04),0,1.96-i*.03)
                spike('pauldron_barb',[p,(p[0]+side*.07,.02,p[2]+.13)],[.035,.001],M['gold'],'spine')
        skull((0,-.20,1.43),.05,'spine')
    if ident=='sharkbyte':
        fin_mesh('dorsal_fin',[(0,.14,1.65),(0,.52,2.07),(0,.16,1.94)],.045,M['skin'],'spine')
        fin_mesh('shark_head_fin',[(0,.035,2.49),(0,.12,2.75),(0,.20,2.45)],.025,M['skin'],'head')
        tail=[(0,.13,1.16),(0,.38,1.03),(0,.69,1.04),(0,.86,1.19)]
        tube('muscular_shark_tail',tail,[.09,.08,.055,.018],M['skin'],'pelvis',20)
        fin_mesh('tail_fluke',[(-.25,.88,1.30),(.22,.88,1.05),(0,.80,1.17)],.035,M['skin'],'pelvis')
    if ident=='chainveil':
        for side in [-1,1]:
            points=[]
            for j in range(25):
                t=j/24;points.append((side*(.4+.18*math.sin(t*math.pi)), -.10,1.2-t*.95))
            chain(points,'hand_'+('L' if side<0 else 'R'))
        ring('choker',(0,0,2.08),.10,.016,M['leather'],'head')
        ell('ruby_pendant',(0,-.116,2.063),(.018,.012,.027),M['gemstone'],'head')
        for side in [-1,1]:
            for i in range(5):
                x=side*(.115+i*.012)
                tube('face_framing_hair',[(x,.01,2.47),(x+side*.045,-.10,2.25),(x+side*.085,-.14,2.03),(x+side*.06,-.20,1.76+i*.025)],[.014,.022,.019,.001],M['hair'],'head',10,flatten=.4)
            # Fine black lace laid over the upper arms and garters.
            suffix='L' if side<0 else 'R'
            for i in range(9):
                z=1.73+i*.014;x=side*(.35+(1.9-z)*.4)
                line('lace_filigree',[(x-.035,-.102,z),(x,-.125,z+.022),(x+.035,-.102,z),(x,-.123,z-.020),(x-.035,-.102,z)],.0025,M['leather'],'upper_arm_'+suffix)
        for side in [-1,1]:ring('earring',(side*.18,-.01,2.22),.026,.004,M['metal'],'head',rotation=(math.pi/2,0,0))


def skull(at,s,bone):
    x,y,z=at
    ell('skull_emblem',(x,y,z),(s,s*.2,s*1.1),M['ivory'],bone)
    for side in [-1,1]:ell('emblem_eye',(x+side*s*.35,y-s*.22,z+s*.15),(s*.23,s*.07,s*.25),M['dark'],bone)
    for i in range(4):cube('emblem_tooth',(x+(i-1.5)*s*.23,y,z-s*.85),(s*.18,s*.25,s*.33),M['ivory'],bone,.001)

def fin_mesh(name,points,thickness,material,bone):
    n=len(points);verts=[(x-thickness/2,y,z) for x,y,z in points]+[(x+thickness/2,y,z) for x,y,z in points]
    faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
    for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update();ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob)
    attach(ob,name,material,bone)
    mod=ob.modifiers.new('Fin edge bevel','BEVEL');mod.width=.012;mod.segments=2
    bpy.context.view_layer.objects.active=ob;bpy.ops.object.modifier_apply(modifier=mod.name)
    return ob

def chain(points,bone):
    for i,p in enumerate(points):ring('individual_chain_link',p,.026,.006,M['metal'] if i%5 else M['gold'],bone,rotation=(math.pi/2,0,(i%2)*math.pi/2),scale=(1,1.3,1))

def signature(cfg,ident):
    if ident=='spinegrin':
        for i in range(8):
            z=1.25+i*.14
            spike('vertebral_spike',[(0,.15,z),(0,.34,z+.10),(0,.44,z+.30)],[.085,.05,.001],M['ivory'] if i%2 else M['accent'],'spine')
        for side in [-1,1]:
            for i in range(4):
                spike('shoulder_spine',[(side*.32,.03,1.91),(side*(.47+i*.03),.06,2.10-i*.05)],[.045,.001],M['ivory'],'spine')
        tube('reptile_tail',[(0,.13,1.15),(0,.35,.95),(0,.65,.80),(.20,.9,.83)],[.10,.08,.045,.001],M['skin'],'pelvis',20)
        for i in range(35):
            x=random.uniform(-.25,.25);z=random.uniform(1.4,1.95)
            ell('raised_scale',(x,-.17,z),(.018,.008,.023),M['skin'])
    if ident=='crystal_fang':
        fur=mat('coarse_black_fur','242332',.82,detail='skin')
        for side in [-1,1]:
            for i in range(55):
                z=random.uniform(1.52,1.98);x=side*(.30+random.uniform(0,.12));y=random.uniform(-.08,.11)
                spike('layered_pelt',[(x,y,z),(x+side*.035,y+.015,z-.065),(x+side*.065,y+.025,z-.105)],[.028,.022,.001],fur,'spine',7)
            for i in range(28):
                x=side*random.uniform(.14,.22);z=random.uniform(2.20,2.44);y=random.uniform(-.03,.12)
                spike('wolf_head_ruff',[(x,y,z),(x+side*.035,y+.025,z-.04),(x+side*.055,y+.04,z-.08)],[.022,.020,.001],fur,'head',7)
        for side in [-1,1]:
            for i in range(6):
                x=side*(.25+i*.038);z=1.91+random.uniform(-.05,.08)
                spike('shoulder_amethyst',[(x,.025,z),(x+side*.13,.03,z+.20),(x+side*.17,.05,z+.32)],[.09,.07,.001],M['gemstone'],'spine',6)
            for i in range(4):
                spike('forearm_crystal',[(side*.59,-.04,1.48-i*.04),(side*.70,-.02,1.6-i*.03)],[.04,.001],M['gemstone'],'forearm_'+('L' if side<0 else 'R'),6)
            for i in range(10):
                spike('wolf_mane',[(side*.18,.02,2.30-i*.022),(side*(.26+.03*math.sin(i)),.07,2.21-i*.025)],[.052,.001],M['skin'],'head',7)
        tube('wolf_tail',[(0,.14,1.1),(0,.4,.8),(.15,.6,.56),(.25,.64,.57)],[.11,.10,.07,.001],M['skin'],'pelvis',16)
    if ident=='lava_stone':
        # An actual fractured surface of overlapping irregular rock plates.
        for i in range(95):
            z=random.uniform(1.25,1.97);angle=random.uniform(0,math.tau)
            radius=.24 if z<1.6 else .34
            x=math.cos(angle)*radius*cfg['width'];y=math.sin(angle)*.18
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,y,z))
            ob=bpy.context.object;ob.scale=(random.uniform(.065,.12),.06,random.uniform(.065,.13));ob.rotation_euler=(random.random(),random.random(),random.random())
            bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);attach(ob,'fractured_basalt_plate',M['skin'])
            for p in ob.data.polygons:p.use_smooth=False
        for side in [-1,1]:
            for j in range(5):
                z=1.35+j*.11
                line('incandescent_fissure',[(side*.04,-.195,z),(side*.15,-.215,z+.04),(side*.25,-.17,z+.025)],.006,M['accent'])
            line('temple_fissure',[(side*.14,-.055,2.44),(side*.10,-.14,2.36),(side*.13,-.12,2.26)],.005,M['accent'],'head')
    if ident=='phoenix_reign':
        for side in [-1,1]:
            # Layered flight feathers with raised quills, folded slightly back.
            for i in range(14):
                t=i/13
                base=Vector((side*(.18+t*.63),.13+t*.10,1.86+t*.15))
                tip=Vector((side*(.60+t*.90),.30+t*.24,1.02+t*.76))
                mid=base.lerp(tip,.55)+Vector((side*.06,-.03,.04))
                tube('sculpted_flight_feather',[base,mid,tip],[.06,.105,.001],M['accent'] if i%4==0 else M['skin'],'spine',10)
                line('feather_quill',[base,mid,tip],.005,M['gold'],'spine')
            for j in range(5):
                spike('cheek_plumage',[(side*.14,.01,2.34-j*.035),(side*.24,.09,2.33-j*.04)],[.05,.001],M['skin'],'head',7)
        for i in range(5):
            tube('tail_feather',[(0,.15,1.2),((i-2)*.13,.40,.70),((i-2)*.19,.65,.25+abs(i-2)*.07)],[.065,.08,.001],M['skin'] if i%2 else M['accent'],'pelvis',10)


def rig_and_export(ident,cfg):
    # A real skinned Skeleton + bone-driven idle, exported as standard glTF.
    arm_data=bpy.data.armatures.new(ident+'_skeleton');arm=bpy.data.objects.new('CharacterRig',arm_data);bpy.context.collection.objects.link(arm)
    bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    bones={'root':((0,0,0),(0,0,.2),None),'pelvis':((0,0,1.05),(0,0,1.35),'root'),'spine':((0,0,1.35),(0,0,1.95),'pelvis'),'head':((0,0,1.95),(0,0,2.48),'spine')};bones.update(JOINTS)
    for name,(head,tail,parent) in bones.items():
        b=arm_data.edit_bones.new(name);b.head=head;b.tail=tail
        if parent:b.parent=arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');arm.select_set(False)
    segments={name:(Vector(p),Vector(q)) for name,(p,q,_) in bones.items() if name not in ['root','foot_L','foot_R']}
    for ob in list(PARTS):
        if ob.type!='MESH':continue
        ob.parent=arm
        if ob.get('weighted_body'):
            groups={name:ob.vertex_groups.new(name=name) for name in segments}
            for v in ob.data.vertices:
                p=ob.matrix_world@v.co;dist=[]
                for name,(a,b) in segments.items():
                    t=max(0,min(1,(p-a).dot(b-a)/(b-a).length_squared));d=(p-(a+(b-a)*t)).length
                    dist.append((d,name))
                dist.sort();first,second=dist[:2];ratio=max(0,min(1,(second[0]-first[0])/.09))
                blend=.5+.5*ratio;groups[first[1]].add([v.index],blend,'REPLACE');groups[second[1]].add([v.index],1-blend,'REPLACE')
        else:
            group=ob.vertex_groups.new(name=ob.get('bone','spine'));group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
        mod=ob.modifiers.new('Skeletal deformation','ARMATURE');mod.object=arm
    # Consolidate all parts into material surfaces: fewer draw calls, same bone weights.
    bpy.ops.object.select_all(action='DESELECT')
    for ob in PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0];bpy.ops.object.join();body_ob=bpy.context.object;body_ob.name='SculptedCharacter'
    # Remove duplicate material slots after joining; glTF merges equal materials.
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
    # Hand-authored vertex countershading on the continuous skin sculpture.
    skin_material=M['skin'];bs=skin_material.node_tree.nodes.get('Principled BSDF')
    vertex_color=skin_material.node_tree.nodes.new('ShaderNodeVertexColor');vertex_color.layer_name='SculptPaint'
    skin_material.node_tree.links.new(vertex_color.outputs['Color'],bs.inputs['Base Color'])
    colors=body_ob.data.color_attributes.new(name='SculptPaint',type='FLOAT_COLOR',domain='CORNER')
    base=np.array([(int(cfg['skin'][i:i+2],16)/255)**2.2 for i in (0,2,4)])
    for poly in body_ob.data.polygons:
        is_skin=body_ob.data.materials[poly.material_index]==skin_material
        for li in poly.loop_indices:
            p=body_ob.matrix_world@body_ob.data.vertices[body_ob.data.loops[li].vertex_index].co
            value=base.copy() if is_skin else np.ones(3)
            if is_skin:
                value*=.94+.06*math.sin(p.z*29+p.x*31+p.y*17)
                if ident=='sharkbyte':
                    under_jaw=(p.z>2.10 and p.z<2.29 and p.y<-.045)
                    throat=(p.z>1.25 and p.z<2.17 and p.y<-.105 and abs(p.x)<.15)
                    if under_jaw or throat:value=np.array([.47,.51,.50])
                if cfg['kind']=='rock':value*=.65+.65*(.5+.5*math.sin(p.x*73+p.z*91))
            colors.data[li].color=(*np.clip(value,0,1),1)
    body_ob.data.calc_loop_triangles()
    # Small, anatomically restrained motion keeps boot/foot bones planted.
    arm.animation_data_create()
    scene=bpy.context.scene;scene.render.fps=30;scene.frame_start=1;scene.frame_end=121
    for frame in [1,31,61,91,121]:
        t=(frame-1)/120*math.tau
        for name in ['spine','head','upper_arm_L','upper_arm_R','forearm_L','forearm_R']:
            bone=arm.pose.bones[name];bone.rotation_mode='XYZ';bone.rotation_euler=(0,0,0)
            if name=='spine':bone.rotation_euler.x=math.sin(t)*.012;bone.rotation_euler.y=math.sin(t)*.008
            elif name=='head':bone.rotation_euler.z=math.sin(t)*.035;bone.rotation_euler.x=math.sin(t+.3)*.012
            else:bone.rotation_euler.y=math.sin(t)*.015*(1 if name.endswith('L') else -1)
            bone.keyframe_insert('rotation_euler',frame=frame,group=name)
    arm.animation_data.action.name='Gallery_Idle'
    scene.frame_set(1)
    # Static source bounds include the full wings, hair, horns, tails and footwear.
    points=[body_ob.matrix_world@v.co for v in body_ob.data.vertices]
    lo=[min(p[i] for p in points) for i in range(3)];hi=[max(p[i] for p in points) for i in range(3)]
    path=OUT/(ident+'.glb')
    bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);body_ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_skins=True,export_materials='EXPORT',export_yup=True,export_apply=False,export_anim_slide_to_zero=True)
    return {'path':str(path.relative_to(ROOT)),'vertices':len(body_ob.data.vertices),'triangles':len(body_ob.data.loop_triangles),'bones':len(arm_data.bones),'materials':len(set(m.name for m in body_ob.data.materials)),
            'bounds_min':[lo[0],lo[2],-hi[1]],'bounds_max':[hi[0],hi[2],-lo[1]],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'bytes':path.stat().st_size,'animation':'Gallery_Idle'}


def build(ident):
    global PARTS,SKIN,M,JOINTS
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    for collection in [bpy.data.meshes,bpy.data.curves,bpy.data.armatures,bpy.data.materials,bpy.data.actions]:
        for block in list(collection):
            if block.users==0:collection.remove(block)
    random.seed(1300+list(CONFIG).index(ident))
    PARTS=[];SKIN=[];JOINTS={};cfg=CONFIG[ident];M=materials(cfg)
    body(cfg,ident);human=head(cfg,ident)
    sculpt_union(SKIN[:],ident+'_anatomy',M['skin'],.012)
    face_details(cfg,ident,human);hair(ident);outfit(cfg,ident);signature(cfg,ident)
    return rig_and_export(ident,cfg)

requested=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else list(CONFIG)
manifest_path=ROOT/'data/character_models.json';manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'version':13,'provenance':'Original procedural Blender mesh sculptures, derived from the supplied character identity references. No source artwork modified.','fighters':{}}
for ident in requested:
    print('BUILD_CHARACTER',ident,flush=True)
    manifest['fighters'][ident]=build(ident)
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
    print('BUILT_CHARACTER',ident,manifest['fighters'][ident],flush=True)
